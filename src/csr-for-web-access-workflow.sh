#!/bin/bash

###
### Workflow for generating and following up CSRs for
### web access to Idemias web server, using client
### certificates
###

. key-admin-lib.sh

##
##   Workflow engine based in current state
##

CURRENT_STATE="$(currentState)"

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
PASSWORD="secret$WORKFLOW"
WEB_CERT_NAME="${WORKFLOW}-redotter-key"

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
	# br -> self_signed_browser_certificate
	# browser_client_cert_$nickname -> self signed browser certificate for person
	generate_csr \
	    "$ACTOR"   "browser_client_cert_$nickname" \
  	    "$DISTINGUISHED_NAME" "$COUNTRY" "$STATE"  \
	    "$LOCATION" "$ORGANIZATION" "$COMMON_NAME"
	
	echo "... done"
	stateTransition "INITIAL" "CSR_READY"
	;;

    CSR_READY)
	echo "Looking for incoming certificate"

	if [[ !  -f "$INCOMING_CERT_FILE" ]] ; then
	    (>&2 echo "$0: Error. Could not find incoming PEM file in '$INCOMING_CERT_FILE'")
	    exit 1
        fi

	if [[  ! -f "$KEYFILE" ]]  ; then
	    (>&2 echo "$0: Error. Could not find key file $KEYFILE")
	    exit 1		
	fi

	if [[ -f "$P12_RESULT_CERT_FILE" ]] ; then
	    (>&2 echo "$0: Error. P12 file already exists: '$P12_RESULT_CERT_FILE', not generating new.")
	else 
	    openssl pkcs12 -export  -password  "pass:${PASSWORD}" -in  "$INCOMING_CERT_FILE" -inkey "$KEYFILE" -name "$WEB_CERT_NAME" -out "$P12_RESULT_CERT_FILE"
	    md5 "$P12_RESULT_CERT_FILE" > "${P12_RESULT_CERT_FILE}.md5"
	fi

	# XXX Should also generate md5 checksum

	GPG_RESULT_FILE="${P12_RESULT_CERT_FILE}.gpg"
	if [[ -f  $GPG_RESULT_FILE ]] ; then
	    (>&2 echo "$0: Error. GPG encrypted P12 file already exists: '$GPG_RESULT_FILE', not generating new.")
	elif  [[ -f "$GPG_RECIPIENT_FILENAME" ]] ; then
	    echo "Attempting to gpg encrypt"
	    GPG_RECIPIENT_EMAIL=$(cat "$GPG_RECIPIENT_FILENAME")
	    regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"

	    if [[ "$GPG_RECIPIENT_EMAIL" =~ $regex ]] ; then
		gpg --encrypt --recipient "$GPG_RECIPIENT_EMAIL" "$P12_RESULT_CERT_FILE"
	    else
		(>&2 echo "$0: Error. Not a valid email address for use with GPG encryption: '$GPG_RECIPIENT_EMAIL'")
		exit 1 
	    fi
	else
	    (>&2 echo "$0: Error. No GPG_RECIPIENT_FILE found in '${GPG_RECIPIENT_FILE}', that is probably a mistake.")
	fi

	# XXX We really want to send an email also, but for now I don't know how to do that in osx.
        #if [[ $? -eq 1  -a -f  "$GPG_RESULT_FILE" ]]
	#   then
	#       
	   #fi
	   # XXX  Set the state to be DONE
	
	;; 
    
    *)    echo "Unknown state '$CURRENT_STATE'"
	(>&2 echo "$0: Error. Could not find dependency $tool")
	exit 1      
esac

