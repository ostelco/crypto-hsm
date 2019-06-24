#!/bin/bash


ES2PLUS_ENDPOINT="https://mconnect-es2-005.staging.oberthur.net:1034"

DOWNLOAD_ORDER_PATH="/gsma/rsp2/es2plus/downloadOrder"
DOWNLOAD_ORDER_PAYLOAD="{\"header\":{\"functionRequesterIdentifier\": \"RequesterID\", \"functionCallIdentifier\": \"TX-567\"}, \"eid\":\"0102030405060708090A0B0C0D0E0F\", \"iccid\":\"01234567890123456789\", \"profileType\":\"myProfileType\"}"

CMD_URL="${ES2PLUS_ENDPOINT}${DOWNLOAD_ORDER_PATH}"
CMD_PAYLOAD=$DOWNLOAD_ORDER_PAYLOAD

curl \
  -vvv \
  --cacert /Users/rmz/git/loltel-esim/loltel-es2-idemia-secrets/crypto-artefacts/idemia/ca.cert.pem \
  --key /Users/rmz/git/loltel-esim/loltel-es2-idemia-secrets/crypto-artefacts/loltel/ck.key \
  --cert  /Users/rmz/git/loltel-esim/loltel-es2-idemia-secrets/crypto-artefacts/idemia/ck.crt.pem \
  --header "X-Admin-Protocol: gsma/rsp/v2.0.0" \
  --header "Content-Type: application/json" \
  --request POST \
  --data "$CMD_PAYLOAD" \
  --insecure \
  $CMD_URL

