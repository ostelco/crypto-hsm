#!/bin/bash

DEPLOYMENT_NAME="$1"

function list_available_deployments {
    echo "Available deployments are:"    >&2
    for x in $(ls ${DEPLOYMENT_SECRETS_HOME} | xargs -n 1 basename | sed 's/.sh//g' | egrep -v '[~#]' ) ; do
	echo "   $x"
    done    
}


if [[ "$#" -ne 1 ]] ; then
    echo "Usage:   $0  deployment-name" >&2
    echo "   ... missing deployment-name" >&2
    list_available_deployments
    exit 1
fi

echo "Preparing deployment named: $DEPLOYMENT_NAME"

if [[ -z "$DEPLOYMENT_SECRETS_HOME" ]] ; then
   echo "Error:  DEPLOYMENT_SECRETS_DIR not set, cannot progress" >&2
   exit 1
fi

if [[ -z $(which kubectl) ]]; then
   echo "Error: Kubectl not installed.  Please reinstall before attempting again" >&2
   exit 1
fi

DEPLOYMENT_PARAMETER_FILE="${DEPLOYMENT_SECRETS_HOME}/${DEPLOYMENT_NAME}.sh"


if [[ ! -f "$DEPLOYMENT_PARAMETER_FILE" ]] ; then
    echo "Could not find deployment parameter file $DEPLOYMENT_PARAMETER_FILE"    >&2    
    list_available_deployments
    exit 1
fi

# Source the parameter file
. $DEPLOYMENT_PARAMETER_FILE

if [[ ! -f "$IDEMIA_ES2_JKS" ]] ; then
   echo "Could not find JKS file $IDEMIA_ES2_JKS"    >&2
   exit 1    
fi

if [[ -z "$DEPLOYMENT_CLUSTER_NAME" ]] ; then
   echo "ERROR: DEPLOYMENT_CLUSTER_NAME variable not set" >&2
   exit 1
fi

if [[ -z "$KUBERNETES_SECRET_STORE" ]] ; then
   echo "ERROR: KUBERNETES_SECRET_STORE variable not set" >&2
   exit 1
fi

# Are we in the right cluster?
if [[ -z $(kubectl config view -o jsonpath='{.contexts[?(@.name == "$DEPLOYMENT_CLUSTER_NAME")].name}') ]] ; then
   echo "Target cluster '$DEPLOYMENT_CLUSTER_NAME' is unknown." >&2
   exit 1
fi

kubectl config use-context "$DEPLOYMENT_CLUSTER_NAME"
if [[ "$DEPLOYMENT_CLUSTER_NAME" != "$(kubectl config current-context)"  ]] ; then
   echo "Could not connect to target cluster $DEPLOYMENT_CLUSTER_NAME"
   exit 1
fi

# Then do the kubernetes thing
kubectl create secret generic ${KUBERNETES_SECRET_STORE} \
         --from-literal dbUser=${DB_USER} \
         --from-literal dbPassword=${DB_PASSWORD} \
         --from-literal dbUrl=${DB_URL} \
         --from-literal wg2User=${WG2_USER} \
         --from-literal wg2ApiKey=${WG2_API_KEY} \
         --from-literal wg2Endpoint=${WG2_ENDPOINT} \
         --from-literal es2plusEndpoint=${ES2_PLUS_ENDPOINT} \
         --from-literal functionRequesterIdentifier=${ES2_PLUS_FUNCTION_REQUEST_IDENTIFIER} \
         --from-file idemiaClientCert="${IDEMIA_ES2_JKS}"

if [[ $? -eq 0 ]] ; then
   echo "Deployment to kubernetes cluster did not go well. Please  investigate" >&2
   exit 1
fi
   
echo "Successul deployment."

