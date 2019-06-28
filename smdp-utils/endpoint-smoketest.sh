#!/bin/bash



### FQDN and crypto-key parameters for prod and dev.  Use only one of them.

## Prod parameters
CERT_HOME=/Users/rmz/my-certs/prime-prod-may-2019/crypto-artefacts

ES2PLUS_ENDPOINT="https://mconnect-es2-005.oberthur.net:1032"
CACERT_FILE=$CERT_HOME/idemia/ca.crt
CERT_FILE=$CERT_HOME/idemia/com.idemia.otcloud.asia.production.RedOtter.es2plus.client.cert.pem
KEY_FILE=$CERT_HOME/redotter/es2plus-prime-csr_cert_prime-prod-may-2019.key


## Dev parameters
# ES2PLUS_ENDPOINT="https://mconnect-es2-005.staging.oberthur.net:1034"
# CACERT_FILE=/Users/rmz/git/loltel-esim/loltel-es2-idemia-secrets/crypto-artefacts/idemia/ca.cert.pem
# KEY_FILE=/Users/rmz/git/loltel-esim/loltel-es2-idemia-secrets/crypto-artefacts/loltel/ck.key
# CERT_FILE=/Users/rmz/git/loltel-esim/loltel-es2-idemia-secrets/crypto-artefacts/idemia/ck.crt.pem



if [[ ! -f "$CACERT_FILE" ]] ; then
    echo "Could not find cacert file '$CACERT_FILE'"
    exit 1
fi


if [[ ! -f "$KEY_FILE" ]] ; then
    echo "Could not find key file '$KEY_FILE'"
    exit 1
fi


if [[ ! -f "$CERT_FILE" ]] ; then
    echo "Could not find cert file '$CERT_FILE'"
    exit 1
fi


### URL and payload parameters (calculated from the above)

DOWNLOAD_ORDER_PATH="/gsma/rsp2/es2plus/downloadOrder"
DOWNLOAD_ORDER_PAYLOAD="{\"header\":{\"functionRequesterIdentifier\": \"RequesterID\", \"functionCallIdentifier\": \"TX-567\"}, \"eid\":\"0102030405060708090A0B0C0D0E0F\", \"iccid\":\"01234567890123456789\", \"profileType\":\"myProfileType\"}"

CMD_URL="${ES2PLUS_ENDPOINT}${DOWNLOAD_ORDER_PATH}"
CMD_PAYLOAD=$DOWNLOAD_ORDER_PAYLOAD


curl \
  -vvv \
  --cacert $CACERT_FILE \
  --key $KEY_FILE \
  --cert $CERT_FILE \
  --header "X-Admin-Protocol: gsma/rsp/v2.0.0" \
  --header "Content-Type: application/json" \
  --request POST \
  --data "$CMD_PAYLOAD" \
  --insecure \
  $CMD_URL

