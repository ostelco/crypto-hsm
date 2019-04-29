#!/bin/bash


###
### Workflow for generating and following up CSRs for
### web access to Idemias web server, using client
### certificates
###

##
## Key length.
##
KEY_LENGTH=4096


##
## Check for dependencies
##
DEPENDENCIES="openssl tar"

for tool in $DEPENDENCIES ; do
  if [[ -z "$(which $tool)" ]] ; then
    (>&2 echo "$0:$LINENO Error. Could not find dependency $tool")
    exit 1
  fi
done



##
## The place where we keep individual workflow data
## $workflow/id/... is where the things go.
##
WORKFLOWS=workflows


if  [[ -z "$1" ]] ; then
    (>&2 echo "$0:$LINENO usage:  $0 name-of-workflow")
    exit 1
fi



function currentState {
    local this_state=$(cat "$WORKFLOW_STATE_PATH")
    if [[ -z "$this_state" ]] ; then
	setState "INITIAL"
	echo "INITIAL"
    else
	echo "$this_state"
    fi
}

function setState {
    local nextState=$1
    echo "$nextState" > "$WORKFLOW_STATE_PATH"
}

function stateTransition {
    local assumedCurrentState=$1
    local nextState=$2
    local thisState="(currentState)"

    if [[ "$currentState" == "$assumedCurrentState" ]] ; then
	(>&2 echo "$0:$LINENO Error. Illegal state transition, assumed current state = '$assumedCurrentState' but in reality it was '$currentState'")
	exit 1
    else
	setState "$nextState"
    fi
}


##
##  Initialization
##

WORKFLOW="$1"
WORKFLOW_PATH="${WORKFLOWS}/${WORKFLOW}"
WORKFLOW_STATE_PATH="${WORKFLOW_PATH}/state.txt"
ARTEFACT_ROOT="${WORKFLOW_PATH}/crypto-artefacts"

if [[ ! -d "$WORKFLOW_PATH" ]] ; then
    mkdir -p "$WORKFLOW_PATH"
    mkdir -p "$ARTEFACT_ROOT"
    setState "INITIAL"
fi


## Load library doing almost all the work.
. ../loltel-csr-roundtrip-for-web-access/key-admin-lib.sh


##
##   Workflow engine based in current state
##



# Misc. names used in the workflow

nickname=$WORKFLOW
ACTOR="redotter"
DISTINGUISHED_NAME="redotter.co"
COUNTRY="SG"
STATE="Singapore"
LOCATION="Singapore"
ORGANIZATION="Red Otter"
COMMON_NAME="$nickname.idemia-web-users.redotter.co"
INCOMING_CERT_FILE="${ARTEFACT_ROOT}/idemia/com.idemia.RedOtter.staging.${WORKFLOW}.ui.client.cert.pem"
KEYFILE=$(key_filename "redotter" "browser_client_cert_$nickname")
P12_RESULT_CERT_FILE=$(p12_filename "redotter" "browser_client_cert_$nickname")
ROLE="${WORKFLOW}_csr_countersigning_ca"


#  XXX Shortcutting logic a bit here, should look in directry etc.
CSR_FILE=$(generate_filename "idemia" 	"com.idemia.10041.notification.2.red-otter" "csr.pem")


function runStateMachine() {
    case "$CURRENT_STATE" in

	INITIAL)
	    stateTransition "INITIAL" "WAITING_FOR_CSR"
	    ;;

	WAITING_FOR_CSR)

	    echo "at #0"

	    if [[ -z "$ACTOR" ]] ; then
		(>&2 echo "$0:$LINENO Error.  ACTOR is null")
		exit 1
	    fi

	    if [[ -z "$ROLE" ]] ; then
		(>&2 echo "$0:$LINENO Error.  ROLE is null")
		exit 1
	    fi

	    echo "at #1"
	# If there is no CSR to sign, then do nothing
	    if [[ ! -f "$CSR_FILE" ]] ; then
		(>&2 echo "$0:$LINENO Error. Could not find dependency $tool")
		exit 1
	    fi

	# Generate a self-signed certificate that can be used for
	# signing purposes.

            echo "at #2"
            CRT_FILENAME=$(crt_filename "$ACTOR" "$ROLE")
	    echo " actor ->$ACTOR,   role->$ROLE"
	    if [[ -z "$CRT_FILENAME" ]] ; then
		echo "CRT filename('$ACTOR',  '$ROLE') is null"
		exit 1
	    fi
	    if [[ ! -f "$CRT_FILENAME" ]] ; then
		echo "at #2.1"		
		self_signed_cert "$ACTOR" "$ROLE" "$DISTINGUISHED_NAME" "$COUNTRY" "$STATE" "$LOCATION" "$ORGANIZATION" "$COMMON_NAME"
		if [[ ! -f "$CRT_FILENAME" ]] ; then
		    echo "---> Didn't generate countersigning cert '$CRT_FILENAME'"
		    exit 1
		fi
	    fi

	    echo "at #3"
	# Now do the actual countersigning
	#   ... but XXX Hardcoding names etc. isn't something we like.

	    RESULT_CRT="${ARTEFACT_ROOT}/idemia/com.idemia.10041.notification.2.red-otter.crt"
	    SIGNING_CRT="${ARTEFACT_ROOT}/redotter/${ROLE}.crt"
	    CERTIFICATE_CHAIN_DOC="${ARTEFACT_ROOT}/redotter/${ROLE}_chain.crt"
	    
	    if [[ ! -f "$RESULT_CRT" ]] ; then
		echo "at #3.1"		
		sign_csr "idemia" "com.idemia.10041.notification.2.red-otter" "$ACTOR" "$ROLE"
	    fi

	# Generate the file to put in the local server, to allow the certificate when it's used to
	# gain access

	# XXX This is ad-hoc, should not be



	    echo "at #4"
	    if [[ ! -f "$CERTIFICATE_CHAIN_DOC" ]] ; then
		if [[ ! -f "$SIGNING_CRT" ]] ; then
		    (>&2 echo "$0:$LINENO Error. Could not find signing crt '$SIGNING_CRT'")
		elif  [[ ! -f "$RESULT_CRT" ]] ; then
		    (>&2 echo "$0:$LINENO Error. Could not find result crt '$RESULT_CRT'")
		else
		    echo "Generate certificate chain $CERTIFICATE_CHAIN_DOC"
		    cat "$RESULT_CRT" "$SIGNING_CRT" > "$CERTIFICATE_CHAIN_DOC"
		fi
	    fi

	# XXX Package the countersigned certificate and the authority certificateso that it can be sent back to the issuer to be used
	    #     in their client.

	    RESULT_PACKAGE="${ARTEFACT_ROOT}/idemia/result-bundle.tgz"
	    tar czf "$RESULT_PACKAGE"  "$RESULT_CRT" "$SIGNING_CRT" 


	    ## Print the expiration dates of the new cert
	    echo "Validity of new certificate"
	    openssl x509 -in "$RESULT_CRT" -text -noout | grep GMT

	    stateTransition  "WAITING_FOR_CSR" "DONE"
	    ;;

	DONE)
	    echo "Done"
	    exit 0
	    ;;

	*)    echo "Unknown state '$CURRENT_STATE'"
	    (>&2 echo "$0:$LINENO Error. Could not find dependency $tool")
	    exit 1
    esac
}


##
##  Main loop
##
while true ; do
    CURRENT_STATE="$(currentState)"
    echo "In state $CURRENT_STATE"
    runStateMachine
done
