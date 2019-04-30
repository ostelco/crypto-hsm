#!/bin/bash

SCRIPTDIR=$(dirname $0)
BASEDIR="$SCRIPTDIR/.."

##
## Get all the secrets from somewhere
##
IDEMIA_ES2_JKS="${BASEDIR}/loltel-es2-idemia-secrets/crypto-artefacts/idemia/idemia-client-cert.jks"



##
##  Check that we actually have all the secrets
##

if [[ -z "$WG2_USER" ]] ;
    (>&2 echo "$0:$LINENO Error.  WG2_USER is empty")
    exit 1
fi


if [[ -z "$WG2_API_KEY" ]] ;
    (>&2 echo "$0:$LINENO Error.  WG2_API_KEY is empty")
    exit 1
fi


if [[ -z "$WG2_ENDPOINT" ]] ;
    (>&2 echo "$0:$LINENO Error.  WG2_ENDPOINT is empty")
    exit 1
fi

if [[ -z "$ES2_PLUS_ENDPOINT" ]] ;
    (>&2 echo "$0:$LINENO Error.  ES2_PLUS_ENDPOINT is empty")
    exit 1
fi


if [[ -z "$IDEMIA_ES2_JKS" ]] ;
    (>&2 echo "$0:$LINENO Error.  IDEMIA_ES2_JKS is empty")
    exit 1
fi


if [[ -z "$IDEMIA_ES2_FUNCTION_REQUESTER_IDENTIFIERS" ]] ;
    (>&2 echo "$0:$LINENO Error.  IDEMIA_ES2_FUNCTION_REQUESTER_IDENTIFIER is empty")
    exit 1
fi


if [[ -z "$PGSQL_URL" ]] ;
    (>&2 echo "$0:$LINENO Error.  PGSQL_URLis empty")
    exit 1
fi



if [[ -z "$PGSQL_USER" ]] ;
    (>&2 echo "$0:$LINENO Error.  PGSQL_USER is empty")
    exit 1
fi

if [[ -z "$PGSQL_PW" ]] ;
    (>&2 echo "$0:$LINENO Error.  PGSQL_PWis empty")
    exit 1
fi


##
##  Now that we know we've got all the secrets, go ahead and
##  use them.
##


kubectl create secret generic simmgr-test-secrets \
         --from-literal dbUser="$PGSQL_USER" \
         --from-literal dbPassword="$PGSQL_PW" \
         --from-literal dbUrl="$PGSQL_URL" \
         --from-literal wg2User="$WG2_USER" \
         --from-literal wg2ApiKey="$WG_API_KEY" \
         --from-literal wg2Endpoint="$WG2_ENDPOINT" \
         --from-literal es2plusEndpoint="$ES2_PLUS_ENDPOINT" \
         --from-literal functionRequesterIdentifier="$IDEMIA_ES2_FUNCTION_REQUESTER_IDENTIFIERS" \
         --from-file    idemiaClientCert="${IDEMIA_ES2_JKS}"

