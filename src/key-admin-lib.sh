#!/bin/bash

##
## Key length. 
##
KEY_LENGTH=4096


##
## The place where we keep individual workflow data
## $workflow/id/... is where the things go.
##


WORKFLOW="$1"

if [[ -z "$WORKFLOWS_PATH" ]] ; then 
    if  [[ ! -z "$WORKFLOWS_HOME" -a ! -z "$WORKFLOW_TYPE" ]]
	WORKFLOW_PATH="$WORKFLOWS_HOME/$WORKFLOW_TYPE" 
    else
	(>&2 echo "$0: Error. Variable WORKFLOWS_PATH is not set, please amend and retry")
	exit 1
    fi
fi

if  [[ -z "$1" ]] ; then
    (>&2 echo "$0: usage:  $0 name-of-workflow")
    exit 1
fi


##
## Check for dependencies
##
DEPENDENCIES="keytool openssl gpg md5 tar"

for tool in $DEPENDENCIES ; do
  if [[ -z "$(which $tool)" ]] ; then
    (>&2 echo "$0:$LINENO Error. Could not find dependency '$tool'")
    exit 1
  fi
done


##
## Setting up directories for the various
## roles, deleting old files. Each of the actors
## (smdp+ and sim manager) are represented by
## a directory.  That directory is then populated with
## misc keys, certificats and csrs.
##


if  [[ -z "$ARTEFACT_ROOT" ]] ; then
    ARTEFACT_ROOT="${WORKFLOWS_PATH}/${WORKFLOW}/crypto-artefacts"
fi

ACTORS="redotter idemia"
for  x in $ACTORS ; do
 if [[ ! -d "$ARTEFACT_ROOT/$x" ]] ; then
  mkdir -p "$ARTEFACT_ROOT/$x"
 fi
done


##
## State management
##

function currentState {
    echo $(cat "$WORKFLOW_STATE_PATH")
}

function setState {
    local nextState=$1
    echo "$nextState" > "$WORKFLOW_STATE_PATH"    
}

function stateTransition {
    local assumedCurrentState=$1
    local nextState=$2
    local thisState="(currentState)"

    if [[ "$currentState" == "$assumedCurrentState" ]] ; then
	(>&2 echo "$0: Error. Illegal state transition, assumed current state = '$assumedCurrentState' but in reality it was '$currentState'")
	exit 1
    else
	setState "$nextState"
    fi
}



##
##  Initialization
##


WORKFLOW_PATH="${WORKFLOWS_PATH}/${WORKFLOW}"
WORKFLOW_STATE_PATH="${WORKFLOW_PATH}/state.txt"
ARTEFACT_ROOT="${WORKFLOW_PATH}/crypto-artefacts" 

GPG_RECIPIENT_FILENAME="${WORKFLOW_PATH}/gpg-email-address.txt"

if [[ ! -d "$WORKFLOW_PATH" ]] ; then
    mkdir -p "$WORKFLOW_PATH"
    mkdir -p "$ARTEFACT_ROOT"
    setState "INITIAL"
fi

if [[ ! -f "$WORKFLOW_STATE_PATH" ]] ; then
    echo "INFO $0: For some reason the state was unknown, resetting to INITIAL"
    setState "INITIAL"    
fi



VALIDITY_PERIOD_IN_DAYS="+720"

##
## Generate filenames from actorname and role
##

function generate_filename {
    local actor=$1
    local role=$2
    local suffix=$3

    if [[ -z "$actor" ]] ; then
	(>&2 echo "No actor given to generate_filename")
	exit 1
    fi
    if [[ -z "$role" ]] ; then
	(>&2 echo "No role given to generate_filename")
	exit 1
    fi

    if [[ -z "$suffix" ]] ; then
	(>&2 echo "No suffix given to generate_filename")
	exit 1
    fi

    echo "${ARTEFACT_ROOT}/${actor}/${role}.${suffix}"
}


function keystore_filename {
    local actor=$1
    local role=$2
    local keystore_type=$3
    echo $(generate_filename $actor "${role}_${keystore_type}" "jks" )
}

function csr_filename {
    local actor=$1
    local role=$2
    echo $(generate_filename $actor $role "csr" )
}


function crt_filename {
    local actor=$1
    local role=$2
    echo $(generate_filename $actor $role "crt" )
}

function crt_pem_filename {
    local actor=$1
    local role=$2
    echo $(generate_filename $actor $role "crt.pem" )
}


function p12_filename {
    local actor=$1
    local role=$2
    echo $(generate_filename $actor $role "p12" )
}

function key_filename {
    local actor=$1
    local role=$2
    echo $(generate_filename $actor $role "key" )
}


function crt_config_filename {
    local actor=$1
    local role=$2
    echo $(generate_filename $actor $role "csr_config" )
}

##
## Generating Certificate Signing Requests (CSRs) and signing them.
##


function generate_cert_config {
    local cert_config=$1
    local keyfile=$2
    local distinguished_name=$3
    local country=$4
    local state=$5
    local location=$6
    local organization=$7
    local common_name=$8

    echo "local cert_config=$1"
    echo "local keyfile=$2"
    echo "local distinguished_name=$3"
    echo "local country=$4"
    echo "local state=$5"
    echo "local location=$6"
    echo "local organization=$7"
    echo "local common_name=$8"

    cat > $cert_config <<EOF
# The main section is named req because the command we are using is req
# (openssl req...)
[ req ]
# This specifies the default key size in bits. If not specified then 512 is
# used. It is used if the -new option is used. It can be overridden by using
# the -newkey option.
default_bits = $KEY_LENGTH

# This is the default filename to write a private key to. If not specified the
# key is written to standard output. This can be overridden by the -keyout
# option.
default_keyfile = $keyfile

# If this is set to no then if a private key is generated it is not encrypted.
# This is equivalent to the -nodes command line option. For compatibility
# encrypt_rsa_key is an equivalent option.
encrypt_key = no

# This option specifies the digest algorithm to use. Possible values include
# md5 sha1 mdc2. If not present then MD5 is used. This option can be overridden
# on the command line.
default_md = sha1

# if set to the value no this disables prompting of certificate fields and just
# takes values from the config file directly. It also changes the expected
# format of the distinguished_name and attributes sections.
prompt = no

# if set to the value yes then field values to be interpreted as UTF8 strings,
# by default they are interpreted as ASCII. This means that the field values,
# whether prompted from a terminal or obtained from a configuration file, must
# be valid UTF8 strings.
utf8 = yes

# This specifies the section containing the distinguished name fields to
# prompt for when generating a certificate or certificate request.
distinguished_name = $distinguished_name

# this specifies the configuration file section containing a list of extensions
# to add to the certificate request. It can be overridden by the -reqexts
# command line switch. See the x509v3_config(5) manual page for details of the
# extension section format.
req_extensions = my_extensions

[ $distinguished_name ]
C = $country
ST = $state
L = $location
O  = $organization
CN = $common_name

[ my_extensions ]
basicConstraints=CA:FALSE
subjectAltName=@my_subject_alt_names
subjectKeyIdentifier = hash

[ my_subject_alt_names ]
DNS.1 = $common_name
# Multiple domains could be listed here, but we're not doing
# doing that now.
EOF
}


##
## The actors then use their own CA  keys to sign their own CA
## and SK certs (a.k.a. "self_signed_cert")
##

SELF_SIGNED_CERT_PASSWORD="eplekake"

function self_signed_cert {
    local actor=$1
    local role=$2
    local distinguished_name=$3
    local country=$4
    local state=$5
    local location=$6
    local organization=$7
    local common_name=$8

    local keyfile=$(key_filename $actor $role)
    local cert_config=$(crt_config_filename $actor $role)
    local crt_file=$(crt_filename $actor $role)

    if [[ -r "$crt_file" ]] ; then
	echo "Self signed certificate file $crt_file already exists, not generating again"
    else
      generate_cert_config "$cert_config" "$keyfile" "$distinguished_name" "$country" "$state" "$location" "$organization" "$common_name"
      openssl req \
	      -passout pass:"$SELF_SIGNED_CERT_PASSWORD" \
	      -config $cert_config \
	      -new -x509 -days $VALIDITY_PERIOD_IN_DAYS  -sha256  \
	      -keyout $keyfile \
	      -out $crt_file
    fi
}

##
## Now generate all the CSRs for both actors.
##

function generate_csr {
    local actor=$1
    local role=$2
    local distinguished_name=$3
    local country=$4
    local state=$5
    local location=$6
    local organization=$7
    local common_name=$8

    local keyfile=$(key_filename $actor $role)
    local cert_config=$(crt_config_filename $actor $role)
    local csr_file=$(csr_filename $actor $role)

    if [[ -r "$csr_file" ]] ; then
	echo "WARN: CSR file file $crt_file already exists, not generating again"
    else
	generate_cert_config "$cert_config" "$keyfile" "$distinguished_name" "$country" "$state" "$location" "$organization" "$common_name"
	openssl req -new  -days $VALIDITY_PERIOD_IN_DAYS -out "$csr_file" -config "$cert_config"
    fi
}


##
## Then sign the various CSRs
##

function sign_csr {
    local issuer_actor=$1
    local issuer_role=$2
    local signer_actor=$3
    local signer_role=$4

    local csr_file=$(csr_filename $issuer_actor $issuer_role)
    local crt_file=$(crt_filename $issuer_actor $issuer_role)
    local ca_crt=$(crt_filename $signer_actor $signer_role)
    local ca_key=$(key_filename $signer_actor $signer_role)

    # We'll take CSRs naked or PEMmed
    if [[ ! -r "$csr_file" ]] ; then
	if [[ -r "${csr_file}.pem" ]] ; then
	   csr_file="${csr_file}.pem"
	else
	    (>&2 echo "key-admin-lib:$LINENO: Error. Could not find issuer csr  $csr_file")
	    exit 1
	fi
    fi

    if [[ ! -r "$ca_crt" ]] ; then
	(>&2 echo "key-admin-lib.sh:$LINENO:  Error. Could not find signer CA crt  $crt_file")
	exit 1
    fi

    if [[ -r "$crt_file" ]] ; then
	echo "Signed certificate file $crt_file already exists, not generating again"
    else
	echo openssl x509 -req -in $csr_file -CA $ca_crt -CAkey $ca_key -CAcreateserial -out $crt_file
	openssl x509 -req -days $VALIDITY_PERIOD_IN_DAYS -in $csr_file -CA $ca_crt -CAkey $ca_key -CAcreateserial -out $crt_file
	if [[ ! -r "$crt_file" ]] ; then
	    (>&2 echo "key-admin-lib:$LINENO: Failed to produce signed certificate in file $crt_file")
	    exit 1
        fi
    fi
}


#
# XXX I'm not convinced this is something we need.
#

##
##  Generate keytool files based on the keys stored
##  in the crypto storage.
##



#
#  Generate and/or populate a keystore file with
#  the certificates given as fourth argument and onwards.
#  First argument is the actor managing the keystore, the
#  second is the role for which it is used (e.g. "client keys")
#  third argument is either "trust" or "keys" depending on if this
#  keystore is used in a "trustkeys" or "secretkeys" role.
#
#  Usage:
#
#     populate_keystore "sim-manager" "ck" "trust" foobar.crt  bartz.crt ..
#
#
function populate_keystore {
    local actor=$1 ; shift
    local role=$1  ; shift
    local keystore_type=$1; shift
    local certs="$*"

    local keystore_filename=$(keystore_filename $actor $role $keystore_type)
    local common_password="superSecreet"

    echo "Creating keystore $keystore_filename"
    for cert in $certs ; do
        echo "     Importing cert $cert"
        keytool  \
             -noprompt -storepass "${common_password}"  \
             -importcert -trustcacerts -alias "$(basename $(dirname $cert))_$(basename $cert)" \
             -file $cert -keystore $keystore_filename
    done
}


##
## Convenience constants
##

EMAIL_ADDRESS_REGEXP="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
