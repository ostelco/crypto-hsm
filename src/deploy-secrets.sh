#!/bin/bash

set -e

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


# Are we in the right cluster?

if [[ -z "$ENV_TYPE" ]] ; then
	echo "ENV_TYPE is not set.  Please set to  'prod' or 'dev'." >&2
	exit 1    
fi

if [[ ! "$ENV_TYPE" == "prod"  ]] ; then
    if [[ ! "$ENV_TYPE" == "dev"  ]] ; then
	echo "ENV_TYPE is set to '$ENV_TYPE', but only 'prod' and 'dev' are legal values." >&2
	exit 1
    fi
fi



# Based on knowing if we're in dev or prod, alculate the namespace
# and gcloud project id.
NAMESPACE="${ENV_TYPE}"
GCLOUD_PROJECT_ID="pi-ostelco-${ENV_TYPE}"

if [[ -z "$GCLOUD_CLUSTER_NAME" ]] ; then
    echo "GCLOUD_CLUSTER_NAME is not set".
    if [[ -z "$ENV_TYPE" ]] ; then
	exit 1
    else
	GCLOUD_CLUSTER_NAME="pi-${ENV_TYPE}"
    fi
fi

if [[ -z "$GCLOUD_PROJECT_ID" ]] ; then
   echo "GCLOUD_PROJECT_ID not set." >&2
   exit 1
fi

if [[ -z "$GCLOUD_COMPUTE_REGION" ]] ; then
   echo "GCLOUD_COMPUTE_REGION not set." >&2
   exit 1
fi

if [[ -z "$NAMESPACE" ]] ; then
   echo "NAMESPACE not set." >&2
   exit 1
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

# Getting access via authentication
gcloud container clusters \
      get-credentials "${GCLOUD_CLUSTER_NAME}" \
      --region "${GCLOUD_COMPUTE_REGION}" \
      --project "${GCLOUD_PROJECT_ID}"

# Then setting which context to us
gcloud config set project $GCLOUD_PROJECT_ID 
kubectl config use-context $(kubectl config get-contexts -o name | grep $GCLOUD_PROJECT_ID)

# Fromo the context, find the kubernetes cluster name
KUBERNETES_CLUSTER_NAME=$(kubectl config get-contexts -o name | grep $GCLOUD_PROJECT_ID )

if [[ -z "$KUBERNETES_CLUSTER_NAME" ]] ; then
   echo "Could not determine KUBERNETES_CLUSTER_NAME." >&2
   exit 1    
fi

# Select which cluster region to work on



if [[ -z "$(gcloud container clusters list | grep $GCLOUD_CLUSTER_NAME)" ]] ; then
    echo "Couldn't find cluster $GCLOUD_CLUSTER_NAME when looking for it using the gcloud command"
    exit 1
fi

# Get credentials so that kubectl can do its job.
gcloud container clusters get-credentials $GCLOUD_CLUSTER_NAME

# Then check if kubectl can see the expected cluster
if [[ -z $(kubectl config view -o jsonpath="{.contexts[?(@.name == \"$KUBERNETES_CLUSTER_NAME\")].name}") ]] ; then
   echo "Target cluster '$KUBERNETES_CLUSTER_NAME' is unknown." >&2
   exit 1
fi


kubectl config use-context "$KUBERNETES_CLUSTER_NAME"
echo "baz"

if [[ "$KUBERNETES_CLUSTER_NAME" != "$(kubectl config current-context)"  ]] ; then
   echo "Could not connect to target cluster $KUBERNETES_CLUSTER_NAME"
   exit 1
fi


##
## At this point we know enough to execute the kubectl command to update secrets.
##

# Delete then update the smdp-cacert
if [[ !  -z "$(kubectl describe secrets/smdp-cacert --namespace=${NAMESPACE} | grep NotFound)" ]] ; then 
    kubectl delete secret smdp-cacert --namespace="${NAMESPACE}"
fi 

kubectl create secret generic smdp-cacert --namespace="${NAMESPACE}" --from-file="${TEMPORARY_ES2PLUS_RETURN_CERT_AND_KEY_FILE}"

# Then do the same for sim manager secrets
if [[ ! -z "$(kubectl describe secrets/simmgr-prod-secrets --namespace=${NAMESPACE} | grep NotFound)" ]] ; then 
    kubectl delete secret simmg-prod-secrets --namespace="${NAMESPACE}"
fi 

kubectl create secret generic simmgr-prod-secrets \
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

##
## Reporting status and cleaning up.
##

if [[ $? -ne 0 ]] ; then
   echo "Deployment to kubernetes cluster did not go well. Please  investigate" >&2
   rm "${TEMPORARY_ES2PLUS_RETURN_CERT_AND_KEY_FILE}"
   exit 1
else
    rm "${TEMPORARY_ES2PLUS_RETURN_CERT_AND_KEY_FILE}"
fi
   
echo "Successul deployment."

