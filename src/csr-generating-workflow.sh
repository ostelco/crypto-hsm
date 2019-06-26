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

CA_CERT_FILE=$(crt_filename "idemia" ca)
P12_RESULT_CERT_FILE=$(p12_filename "$ACTOR" "${WORKFLOW_TYPE}_${nickname}")
JKS_RESULT_FILE=$(jks_filename "$ACTOR" "${WORKFLOW_TYPE}_${nickname}")
P12_PASSWORD="secret$WORKFLOW"
P12_CERT_NAME="${WORKFLOW}-$ACTOR-key"

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
            (>&2 echo "$0: Error. Could not find incoming cert file file in '$INCOMING_CERT_FILE'")
            exit 1
        fi

        echo " ... found certificate $INCOMING_CERT_FILE"
        
        echo "Looking for keyfile ..."  
        if [[  ! -f "$KEYFILE" ]]  ; then
            (>&2 echo "$0: Error. Could not find key file $KEYFILE")
            exit 1              
        fi
        echo " ... found  keyfile $KEYFILE"


	echo "Looking for remote ca-cert ..."  
        if [[  ! -f "$CA_CERT_FILE" ]]  ; then
            (>&2 echo "$0: Error. Could not find remote ca-cert file $CA_CERT_FILE")
            exit 1              
        fi
        echo " ... found  remote ca-cert file $CA_CERT_FILE"

	        
        if [[ -f "$P12_RESULT_CERT_FILE" ]] ; then
            (>&2 echo "$0: Error. P12 file already exists: '$P12_RESULT_CERT_FILE', not generating new.")
        else
            echo "Generating pkcs12 file to use when contacting external service"
            openssl pkcs12 \
                    -export \
                    -password  "pass:${P12_PASSWORD}" \
                    -in  "$INCOMING_CERT_FILE" \
                    -inkey "$KEYFILE" \
                    -name "$P12_CERT_NAME" \
                    -out "$P12_RESULT_CERT_FILE"
            if [[ $? -eq 1 ]] ; then
                (>&2 echo "$0: Error. Could not generate pkcs12 file")
                exit 1
            fi

            $MD5 "$P12_RESULT_CERT_FILE" > "${P12_RESULT_CERT_FILE}.md5"
        fi

        # Generate java keystore file containing the signed
        # certificate
        # XXXX Perhaps this?populate_keystore "$ACTOR" "ck" "trust" foobar.crt  bartz.crt ..
        # But we'll just convert the P12 certificate into a java .jks certificate


        if [[ -z "$JKS_RESULT_FILE" ]] ; then
            (>&2 echo "$0: Error. JKS_RESULT_FILE is empty, bailing out.")
            exit 1
        fi
        if [[ -f "$JKS_RESULT_FILE" ]] ; then
            (>&2 echo "$0: Error. JKS file already exists: '$JKS_RESULT_FILE', not generating new.")
	    exit 1
        fi

	# Eventually this password should be part of
	# the set of secrets, but for now it's just a not so random string.
        SECRET_KEYSTORE_PASSWORD="foobar"

	# Then generate a new java keystore with a dummy certifiate in it, and then remove
	# that cert leaving an empty keystore.
	
	keytool -genkey -keyalg RSA \
		-dname "cn=Mark Jones, ou=Java, o=Oracle, c=US" \
		-storepass "$SECRET_KEYSTORE_PASSWORD" \
		-alias endeca -keystore "$JKS_RESULT_FILE"

	keytool -delete -alias endeca \
		-storepass "$SECRET_KEYSTORE_PASSWORD" \
		-keystore "$JKS_RESULT_FILE"


	# Import the remote root ca into the p12 file
	keytool -importcert -noprompt \
		-alias remote-ca \
		-file "${CA_CERT_FILE}" \
		-keystore "$P12_RESULT_CERT_FILE" \
		-storepass "$P12_PASSWORD"
	
	# Finally insert the content of the .p12 storage into the
	# java keystore.
        
        keytool -importkeystore -v \
                -srckeystore "$P12_RESULT_CERT_FILE" \
                -srcstoretype PKCS12 \
                -srcstorepass "$P12_PASSWORD" \
                -destkeystore "$JKS_RESULT_FILE" \
                -deststoretype JKS \
                -deststorepass "$SECRET_KEYSTORE_PASSWORD"

	

	
        
        exit 1
	# Don't believe it!
        stateTransition  "CSR_READY" "DONE"
        ;;

    DONE) echo "We're done here, nothing more to do"
          exit 0
          ;;
    
    *)    echo "Unknown state '$CURRENT_STATE'"
          exit 1
          ;;
esac

