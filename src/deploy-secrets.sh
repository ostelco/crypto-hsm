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

if [[ -z "$(which gcloud)" ]] ; then
   echo "gcloud not installed, please reinstall before attempting again" >&2
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


# Check that we actually got the parameters we need.
if [[ ! -f "$IDEMIA_ES2_JKS" ]] ; then
   echo "Could not find JKS file $IDEMIA_ES2_JKS"    >&2
   exit 1    
fi

if [[ -z "$DEPLOYMENT_CLUSTER_NAME" ]] ; then
   echo "ERROR: DEPLOYMENT_CLUSTER_NAME variable not set" >&2
   exit 1
fi

if [[ -z "$KUBERNETES_SECRETS_STORE" ]] ; then
   echo "ERROR: KUBERNETES_SECRETS_STORE variable not set" >&2
   exit 1
fi

# Are we in the right cluster?

if [[ -z "$GCLOUD_CLUSTER_NAME" ]] ; then
    echo "GCLOUD_CLUSTER_NAME is not set".
    exit 1
fi

if [[ -z "$GCLOUD_PROJECT_ID" ]] ; then
   echo "GCLOUD_PROJECT_ID not set." >&2
   exit 1
fi

#if [[ -z "$GCLOUD_COMPUTE_ZONE" ]] ; then
#   echo "GCLOUD_COMPUTE_ZONE not set." >&2
#   exit 1
#fi

if [[ -z "$GCLOUD_COMPUTE_REGION" ]] ; then
   echo "GCLOUD_COMPUTE_REGION not set." >&2
   exit 1
fi

if [[ -z "$NAMESPACE" ]] ; then
   echo "NAMESPACE not set." >&2
   exit 1
fi

if [[ ! "$NAMESPACE" == "prod"  ]] ; then
    if [[ ! "$NAMESPACE" == "dev"  ]] ; then
	echo "NAMESPACE is set to '$NAMESPACE', but only 'prod' and 'dev' are legal values." >&2
	exit 1
    fi
fi

if [[ -z "${CONCATENATED_ES2PLUS_RETURN_CHANNEL_CERT_AND_KEY_FILE}" ]]; then
   echo "CONCATENATED_ES2PLUS_RETURN_CHANNEL_CERT_AND_KEY_FILE not set." >&2
   exit 1
fi

if [[ ! -f "${CONCATENATED_ES2PLUS_RETURN_CHANNEL_CERT_AND_KEY_FILE}" ]]; then
   echo "file CONCATENATED_ES2PLUS_RETURN_CHANNEL_CERT_AND_KEY_FILE='${CONCATENATED_ES2PLUS_RETURN_CHANNEL_CERT_AND_KEY_FILE}' does not exist." >&2
   exit 1
fi

# Copy from original to local to ensure correct filename and local path
TEMPORARY_ES2PLUS_RETURN_CERT_AND_KEY_FILE=tls.crt
cp "${CONCATENATED_ES2PLUS_RETURN_CHANNEL_CERT_AND_KEY_FILE}" "${TEMPORARY_ES2PLUS_RETURN_CERT_AND_KEY_FILE}"



##
## Setting up access to the cluster (regional, not zonal)
##

# Then (obviously) update the gcloud command itself
gcloud components update

### XXX FIX THIS ( parameterize with prod/dev)
gcloud container clusters get-credentials pi-dev --region europe-west1 --product pi-ostelco-dev

# Configure the cluster so kubernetes can do its job using the gcloud command
gcloud config set project "$GCLOUD_PROJECT_ID"
#gcloud config set compute/zone "$GCLOUD_COMPUTE_ZONE"
gcloud config set compute/region "$GCLOUD_COMPUTE_REGION"

if [[ -z "$(gcloud container clusters list | grep $GCLOUD_CLUSTER_NAME)" ]] ; then
    echo "Couldn't find cluster $GCLOUD_CLUSTER_NAME when looking for it using the gcloud command"
    exit 1
fi

gcloud container clusters get-credentials $GCLOUD_CLUSTER_NAME

# Then check if kubectl can see the expected cluster

if [[ -z $(kubectl config view -o jsonpath="{.contexts[?(@.name == \"$DEPLOYMENT_CLUSTER_NAME\")].name}") ]] ; then
   echo "Target cluster '$DEPLOYMENT_CLUSTER_NAME' is unknown." >&2
   exit 1
fi

kubectl config use-context "$DEPLOYMENT_CLUSTER_NAME"
if [[ "$DEPLOYMENT_CLUSTER_NAME" != "$(kubectl config current-context)"  ]] ; then
   echo "Could not connect to target cluster $DEPLOYMENT_CLUSTER_NAME"
   exit 1
fi


# Delete ehan update the smdp-cacert
kubectl delete secret smdp-cacert --namespace="${NAMESPACE}"
kubectl create secret generic smdp-cacert --namespace="${NAMESPACE}" --from-file="${TEMPORARY_ES2PLUS_RETURN_CERT_AND_KEY_FILE}"

# Then set the simmgr secrets
# Then do the kubernetes thing
kubectl create secret generic ${SIM_MANAGER_SECRET} \
         --namespace="${NAMESPACE}" \
         --from-literal dbUser=${DB_USER} \
         --from-literal dbPassword=${DB_PASSWORD} \
         --from-literal dbUrl=${DB_URL} \
         --from-literal wg2User=${WG2_USER} \
         --from-literal wg2ApiKey=${WG2_API_KEY} \
         --from-literal wg2Endpoint=${WG2_ENDPOINT} \
         --from-literal es2plusEndpoint=${ES2_PLUS_ENDPOINT} \
         --from-literal functionRequesterIdentifier=${ES2_PLUS_FUNCTION_REQUEST_IDENTIFIER} \
         --from-file idemiaClientCert="${IDEMIA_ES2_JKS}"



if [[ $? -ne 0 ]] ; then
   echo "Deployment to kubernetes cluster did not go well. Please  investigate" >&2
   exit 1
fi

rm "${TEMPORARY_ES2PLUS_RETURN_CERT_AND_KEY_FILE}"
   
echo "Successul deployment."

