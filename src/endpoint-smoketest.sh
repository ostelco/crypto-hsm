#!/bin/bash


ES2PLUS_ENDPOINT="https://mconnect-es2-005.staging.oberthur.net:1034"

DOWNLOAD_ORDER_PATH="/gsma/rsp2/es2plus/downloadOrder"
DOWNLOAD_ORDER_PAYLOAD="{\"header\":{\"functionRequesterIdentifier\": \"RequesterID\", \"functionCallIdentifier\": \"TX-567\"}, \"eid\":\"0102030405060708090A0B0C0D0E0F\", \"iccid\":\"01234567890123456789\", \"profileType\":\"myProfileType\"}"

CMD_URL="${ES2PLUS_ENDPOINT}${DOWNLOAD_ORDER_PATH}"
CMD_PAYLOAD=$DOWNLOAD_ORDER_PAYLOAD

#         CACERT_KEY_FILE=/Users/rmz/git/loltel-esim/loltel-es2-idemia-secrets/crypto-artefacts/loltel/ck.key
#        CACERT_CERT_FILE=/Users/rmz/git/loltel-esim/loltel-es2-idemia-secrets/crypto-artefacts/idemia/ca.cert.pem
# COUNTERSIGNED_CERT_FILE=/Users/rmz/git/loltel-esim/loltel-es2-idemia-secrets/crypto-artefacts/idemia/ck.crt.pem


CACERT_KEY_FILE=/home/rmz/git/secrets/workflows/es2plus-prime-csr/prime-prod-may-2019/crypto-artefacts/redotter/es2plus-prime-csr_cert_prime-prod-may-2019.key
CACERT_CSR_FILE=/home/rmz/git/secrets/workflows/es2plus-prime-csr/prime-prod-may-2019/crypto-artefacts/redotter/es2plus-prime-csr_cert_prime-prod-may-2019.csr
COUNTERSIGNED_CERT_FILE=/home/rmz/git/secrets/workflows/es2plus-prime-csr/prime-prod-may-2019/crypto-artefacts/redotter/com.idemia.otcloud.asia.production.RedOtter.es2plus.client.cert.pem


if [[ ! -f "$CACERT_KEY_FILE" ]] ; then
    echo "No CACERT_KEY_FILE"
    exit 1
fi


if [[ ! -f "$CACERT_CSR_FILE" ]] ; then
    echo "No CACERT_CSR_FILE"
    exit 1
fi

if [[ ! -f "$COUNTERSIGNED_CERT_FILE" ]] ; then
    echo "No COUNTERSIGNED_CERT_FILE"
    exit 1
fi


curl \
  -vvv \
  --cacert $CACERT_CSR_FILE \
  --key $CACERT_KEY_FILE \
  --cert  $COUNTERSIGNED_CERT_FILE \
  --header "X-Admin-Protocol: gsma/rsp/v2.0.0" \
  --header "Content-Type: application/json" \
  --request POST \
  --data "$CMD_PAYLOAD" \
  --insecure \
  $CMD_URL

