#!/bin/bash

##
##   Workflow engine based in current state
##

CURRENT_STATE="$(currentState)"

# Misc. names used in the workflow

nickname="${WORKFLOW}"
ACTOR="redotter"
DISTINGUISHED_NAME="redotter.co"
COUNTRY="SG"
STATE="Singapore"
LOCATION="Singapore"
ORGANIZATION="Red Otter"
COMMON_NAME="${nickname}.${WORKFLOW_TYPE}.redotter.co"
KEYFILE=$(key_filename "redotter" "${WORKFLOW_TYPE}_cert_${nickname}")

P12_RESULT_CERT_FILE=$(p12_filename "redotter" "${WORKFLOW_TYPE}_${nickname}")
PASSWORD="secret$WORKFLOW"
WEB_CERT_NAME="${WORKFLOW}-redotter-key"

INCOMING_CERT_FILES=(${ARTEFACT_ROOT}/idemia/*.pem)
INCOMING_CERT_FILE=${INCOMING_CERT_FILES[0]}


##
##   XXX The typcial workflow should be  that we transition from state to state,
##   and at some point we are not able to transition any further, at that point we either
##   exit with an error code (if we couldn't continue to the en)
##   or with a success code, of we  are in a declared final state.
##


CURRENT_STATE="$(currentState)"

case "$CURRENT_STATE" in

    INITIAL)
	echo "In initial state, will generate certificate and CSR"

	#  Setting parameters in an ad-hoc and not entirely useful manner.
	
	echo "Generating generating csr & key ..."
	generate_csr \
	    "$ACTOR"   "${WORKFLOW_TYPE}_cert_$nickname" \
  	    "$DISTINGUISHED_NAME" "$COUNTRY" "$STATE"  \
	    "$LOCATION" "$ORGANIZATION" "$COMMON_NAME"

	if [[  ! -f "$KEYFILE" ]]  ; then
	    (>&2 echo "$0: Error. Could not find key file $KEYFILE that was supposed to be generated")
	    exit 1		
	fi
	
	echo "... done"

	stateTransition "INITIAL" "CSR_READY"
	;;

    CSR_READY)
	echo "Looking for incoming certificate ..."

	if [[ ! -z "$INCOMING_CERT_FILE" ]] &&  [[ !  -f "$INCOMING_CERT_FILE" ]] ; then
	    (>&2 echo "$0: Error. Could not find incoming PEM file in '$INCOMING_CERT_FILE'")
	    exit 1
        fi

	echo " ... found certificate $INCOMING_CERT_FILE"

	echo "Looking for keyfile ..."	
	if [[  ! -f "$KEYFILE" ]]  ; then
	    (>&2 echo "$0: Error. Could not find key file $KEYFILE")
	    exit 1		
	fi
	echo " ... found  keyfile $KEYFILE"	# XXX Should also generate md5 checksum

	
	if [[ -f "$P12_RESULT_CERT_FILE" ]] ; then
	    (>&2 echo "$0: Error. P12 file already exists: '$P12_RESULT_CERT_FILE', not generating new.")
	else
	    echo "Generating pkcs12 file to use when contacting external service"
	    openssl pkcs12 -export  -password  "pass:${PASSWORD}" -in  "$INCOMING_CERT_FILE" -inkey "$KEYFILE" -name "$WEB_CERT_NAME" -out "$P12_RESULT_CERT_FILE"
	    if [[ $? -eq 1 ]] ; then 
		(>&2 echo "$0: Error. Could not generate pkcs12 file")
		exit 1
	    fi

	    $MD5 "$P12_RESULT_CERT_FILE" > "${P12_RESULT_CERT_FILE}.md5"
	fi

	
	exit 1
	stateTransition  "CSR_READY" "DONE"
	;;

    DONE) echo "We're done here, nothing more to do"
	  exit 0
	  ;;
    
    *)    echo "Unknown state '$CURRENT_STATE'"
	  exit 1
	  ;;
esac

