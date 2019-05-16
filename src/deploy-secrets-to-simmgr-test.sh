#!/bin/bash

DEPLOYMENT_NAME="$0"

echo "Preparing deployment named: $DEPLOYMENT_NAME"

if [[ -z "$DEPLOYMENT_SECRETS_HOME]] ; then
   echo "Error:  SECRETS_DIR not set, cannot progress"
   exit 1
fi

if [[ -z $(which kubectl) ]]; then
   echo "Error: Kubectl not installed.  Please reinstall before attempting again"
   exit 1
fi

DEPLOYMENT_PARAMETER_FILE="${DEPLOYMENT_SECRETS_HOME}/${DEPLOYMENT_NAME}.sh"

if [[ ! -f "$DEPLOYMENT_PARAMETER_FILE" ]] ; then
   echo "Could not file deployment parameter file $DEPLOYMENT_PARAMETER_FILE"
   exit 1
fi

# Source the parameter file
. $DEPLOYMENT_PARAMETER_FILE


# Do a bunch of sanity checks based on the parameters from the deployment
# parameter file

   # XXX TBD

# Then do the kubernetes thing
kubectl create secret generic simmgr-test-secrets \
         --from-literal dbUser=${DB_USER} \
         --from-literal dbPassword=${DB_PASSWORD} \
         --from-literal dbUrl=${DB_URL} \
         --from-literal wg2User=${WG2_USER} \
         --from-literal wg2ApiKey=${WG2_API_KEY} \
         --from-literal wg2Endpoint=${WG2_ENDPOINT} \
         --from-literal es2plusEndpoint=${ES2_PLUS_ENDPOINT} \
         --from-literal functionRequesterIdentifier=${ES2_PLUS_FUNCTION_REQUEST_IDENTIFIER} \
         --from-file idemiaClientCert="${IDEMIA_ES2_JKS}"

echo "Deployment done."
