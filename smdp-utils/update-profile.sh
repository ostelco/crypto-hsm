#!/bin/bash

##
##  Usage:  update-profile.sh id cmd1 cmd2 cmd3 ...
##    - where id is a profile id in the range 0..14
##    - where cmd is one of:
##        - es2recover: Will reset the profile in the SM-DP+
##        - es2cancel: Will reset the profile in the SM-DP+ in a different way
##        - es2download: Will prepare the profile for downloading
##        - es2confirm: Will confirm the profile for downloading, and return a
##          an activation code
##        - hlrProvision: Will provision the IMSI/ICCID/MSISDN combination in the HSS.
##
##  Typical usage:  update-profile.sh 1 reset download confirm provision
##

SCRIPTNAME=$0

PROFILE_ID="$1"
shift


if [[ "$PROFILE_ID" = "iccid" ]] ; then
    ICCID="$1"
    echo "Set ICCID to be $ICCID"
    shift
fi

COMMANDS=$*


##
## Checking for dependencies
##

DEPENDENCIES="curl jq"

for DEP in $DEPENDENCIES ; do
    if   [[ -z "$(which $DEP)"  ]] ; then
	echo "$SCRIPTNAME ERROR: Could not find depencency '$DEP'.   You need to install it before trying again."
	exit 1
    fi
done

##
## Check the input parameter, the profile ID (should be a number in the range 0..13)
##

MAX_PROFILE_ID=21

if  [[ -z "$PROFILE_ID"  ]] ; then
    echo "$SCRIPTNAME ERROR: No profile ID given as paramter, needs to be an integer in the range 0..$MAX_PROFILE_ID"
    exit 1
fi

if  (( !( 0 <= $PROFILE_ID && $PROFILE_ID <= $MAX_PROFILE_ID) )) ; then
    echo "$SCRIPTNAME ERROR: Profile ID is '$PROFILE_ID' which is not an integer in the range 0..$MAX_PROFILE_ID"
    exit 1
fi


##
## Parameters used for all of the invocations.
##

### Get all this from a file containing secrets


SCRIPT_SECRETS_FILE=~/.esim_secrets/secret_variables.sh

CERT_HOME=/Users/rmz/my-certs/prime-prod-may-2019/crypto-artefacts
ES2PLUS_ENDPOINT="https://mconnect-es2-005.oberthur.net:1032"
CACERT_FILE=$CERT_HOME/idemia/ca.crt
CERT_FILE=$CERT_HOME/idemia/com.idemia.otcloud.asia.production.RedOtter.es2plus.client.cert.pem
KEY_FILE=$CERT_HOME/redotter/es2plus-prime-csr_cert_prime-prod-may-2019.key
FUNCTION_REQUESTER_IDENTIFIER="1.3.6.1.4.1.12748.2.1"

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





##
## Then check that we have all the parameters/secrets we need
##
if  [[ -z "$ES2PLUS_ENDPOINT"  ]] ; then
    echo "$SCRIPTNAME ERROR: No ES2PLUS_ENDPOINT variable set"
    exit 1
fi


if  [[ -z "$FUNCTION_REQUESTER_IDENTIFIER"  ]] ; then
    echo "$SCRIPTNAME ERROR: No FUNCTION_REQUESTER_IDENTIFIER variable set"
    exit 1
fi


##
## Check input parameters, the commands should all be legal
##


for CMD in $COMMANDS ; do
    if [[ ! ( "$CMD" = "es2recover" ||  "$CMD" = "es2cancel" ||  "$CMD" = "es2download" || "$CMD" = "es2profileStatus" ||  "$CMD" = "es2confirm" ||  "$CMD" = "hlrProvision" )  ]] ; then
        echo "$SCRIPTNAME ERROR: Unknown command '$CMD'.  Legal commands are es2recover, es2cancel, es2download, es2confirm, es2profileStatus and hlrProvision. "
        exit 1
    fi
done



# This script will use MSISDNs in the range= 4790309900 .. 4790309999

##
## Then out the profile parameters
##


if [[ "$PROFILE_ID" = "iccid" ]] ; then
    # Already parsed
    echo "Profile set to ICCID=$ICCID"
elif [[ "$PROFILE_ID" = "0" ]] ; then
    PROFILE_STATUS="inactive or defective"
    PROFILE_NICKNAME="IDEMIA dummy profile"
    ICCID=89601618070300000102
    EID=
    IMSI=
    QR='LPA:1$rsp-0002.oberthur.net$HHGNM-CW1ZD-CDI3N-B2BEW'
elif [[ "$PROFILE_ID" = "1" ]] ; then
    PROFILE_STATUS="inactive or defective"
    PROFILE_NICKNAME="Oisin's iphone"
    ICCID=8947000000000000012
    IMSI=242017100100000
    EID=
    MSISDN=
    QR='LPA:1$rsp-0002.oberthur.net$NEDU4-UPJSW-UDVJ2-S3LVN'
elif [[ "$PROFILE_ID" = "2" ]] ; then
    PROFILE_STATUS="inactive or defective"
    PROFILE_NICKNAME="Oisin's iphone"
    ICCID=8947000000000000020
    IMSI=242017100100001
    EID=
    MSISDN=
    QR='LPA:1$rsp-0002.oberthur.net$NEDU4-UPJSW-UDVJ2-S3LVN'
elif [[ "$PROFILE_ID" = "3" ]] ; then
    PROFILE_NICKNAME="EncryptedRemoteES2Client test article"
    PROFILE_STATUS="Cycled through a typical lifecycle every time the test runs"
    ICCID=8947000000000000038
    IMSI=242017100100002
    EID=
    QR='LPA:1$rsp-0002.oberthur.net$UC4PA-EZ6Y0-UL6X8-MQCPF'
elif [[ "$PROFILE_ID" = "4" ]] ; then
    PROFILE_STATUS="inactive or defective"
    PROFILE_NICKNAME="Rmz iphone"
    ICCID=8947000000000000046
    IMSI=242017100100003
    EID=
    MSISDN=4790309997
    QR='LPA:1$rsp-0002.oberthur.net$WJ7AZ-QYPVH-UU4DZ-DHCQC'
elif [[ "$PROFILE_ID" = "5" ]] ; then
    PROFILE_STATUS="Fully functional"
    PROFILE_NICKNAME="Vihang's pixel phone"
    IMSI=242017100100004
    EID=
    MSISDN=4790309996
    ICCID=8947000000000000053
    QR=''
elif [[ "$PROFILE_ID" = "6" ]] ; then
    PROFILE_STATUS="Acgive, working"
    PROFILE_NICKNAME="Vihang's pixel second sim"
    MSISDN=4790309995
    EID=
    IMSI=242017100100005
    ICCID=8947000000000000061
    QR='LPA:1$rsp-0002.oberthur.net$BOFQB-RUDEF-G8CFN-DHJ93'
elif [[ "$PROFILE_ID" = "7" ]] ; then
    PROFILE_NICKNAME="Vihang's iphone"
    PROFILE_STATUS="inactive or defective"
    MSISDN=4790309994
    ICCID=8947000000000000079
    IMSI=242017100100006
    QR='LPA:1$rsp-0002.oberthur.net$2KUND-MVGHD-6GCDP-JEZEG'
    EID=
elif [[ "$PROFILE_ID" = "8" ]] ; then
    PROFILE_STATUS="Active, working"
    PROFILE_NICKNAME="Martin's pixel phone"
    MSISDN=4790309993
    EID=
    IMSI=242017100100007
    ICCID=8947000000000000087
    QR='LPA:1$rsp-0002.oberthur.net$8U7FZ-4UET4-LPHVS-AIVMV'
elif [[ "$PROFILE_ID" = "9" ]] ; then
    PROFILE_STATUS="Active, working"
    PROFILE_NICKNAME="Working singapore pixel phone profile"
    ICCID=8947000000000000095
    EID=
    IMSI=242017100100008
    MSISDN=4790309992
    ACCESSCODE=FA8X1-XO1XT-S6ZUN-RCZR1
    QR='LPA:1$rsp-0002.oberthur.net$FA8X1-XO1XT-S6ZUN-RCZR1'
elif [[ "$PROFILE_ID" = "10" ]] ; then
    PROFILE_STATUS="Active, working"
    PROFILE_NICKNAME="Silje's iphone"
    EID=
    ICCID=8947000000000000103
    IMSI=242017100100009
    MSISDN=4790309991
    ACCESSCODE=K5EEM-9BWJG-8WP77-EKMKW
    QR='LPA:1$rsp-0002.oberthur.net$K5EEM-9BWJG-8WP77-EKMKW'
elif [[ "$PROFILE_ID" = "11" ]] ; then
    PROFILE_STATUS="Test"
    PROFILE_NICKNAME="Temporary proile, testing (LOLTEL_IPHONE_1)"
    EID=
    ICCID=8947000000000001135
    IMSI=242017100010112
    MSISDN=
    ACCESSCODE=
    QR=
elif [[ "$PROFILE_ID" = "12" ]] ; then
    PROFILE_STATUS="Test"
    PROFILE_NICKNAME="Temporary proile, testing (LOLTEL_IPHONE_1)"
    EID=
    ICCID=8947000000000001143
    IMSI=242017100010113
    MSISDN=
    ACCESSCODE=
    QR=

elif [[ "$PROFILE_ID" = "13" ]] ; then
    PROFILE_STATUS="Test"
    PROFILE_NICKNAME="Temporary proile, testing (LOLTEL_IPHONE_1)"
    EID=
    ICCID=8947000000000001143
    IMSI=242017100010113
    MSISDN=
    ACCESSCODE=
    QR=
elif [[ "$PROFILE_ID" = "14" ]] ; then
    PROFILE_STATUS="Test"
    PROFILE_NICKNAME="Temporary proile, testing (LOLTEL_IPHONE_1)"
    EID=
    ICCID=8947000000000001093
    IMSI=242017100010108
    MSISDN=4790309703
    ACCESSCODE=QC4FW-VVXOG-YGYBC-QCHHU
    QR=
elif [[ "$PROFILE_ID" = "15" ]] ; then
    PROFILE_STATUS="Test"
    PROFILE_NICKNAME="Temporary proile, testing (LOLTEL_ANDROID_1)"
    EID=
    ICCID=8947000000000001085
    IMSI=
    MSISDN=
    ACCESSCODE=
    QR=
elif [[ "$PROFILE_ID" = "16" ]] ; then
    PROFILE_STATUS="Test"
    PROFILE_NICKNAME="Temporary proile, testing (LOLTEL_ANDROID_1)"
    EID=
    ICCID=8947000000000002042
    IMSI=
    MSISDN=
    ACCESSCODE=
    QR=
elif [[ "$PROFILE_ID" = "17" ]] ; then
    PROFILE_STATUS="Test"
    PROFILE_NICKNAME="Temporary proile, testing (LOLTEL_IPHONE_1)"
    EID=
    ICCID=8947000000000002075
    IMSI=
    MSISDN=
    ACCESSCODE=
    QR=

elif [[ "$PROFILE_ID" = "18" ]] ; then
    PROFILE_STATUS="Test"
    PROFILE_NICKNAME="M1 idemia android 1"
    EID=
    ICCID=8965030119040000075
    IMSI=
    MSISDN=
    ACCESSCODE=
    QR=
elif [[ "$PROFILE_ID" = "19" ]] ; then
    PROFILE_STATUS="Test"
    PROFILE_NICKNAME="M1 idemia android 2"
    EID=
    ICCID=8965030119040000067
    IMSI=
    MSISDN=
    ACCESSCODE=
    QR=
elif [[ "$PROFILE_ID" = "20" ]] ; then
    PROFILE_STATUS="Test"
    PROFILE_NICKNAME="M1 idemia android 2"
    EID=
    ICCID=8947000000000007108
    IMSI=242017100010709
    MSISDN=4790309204
    ACCESSCODE=
    QR=
elif [[ "$PROFILE_ID" = "21" ]] ; then
    PROFILE_STATUS="Test"
    PROFILE_NICKNAME="M1 idemia android 2"
    EID=
    ICCID=8947000000000007090
    IMSI=242017100010708
    MSISDN=4790309204
    ACCESSCODE=4790309205
    QR=
else
    echo "$SCRIPTNAME ERROR: Unknown profile name '$PROFILE_ID'"
    exit 1
fi




# ... A simple sanity check.
if [[  -z "$ICCID" ]]; then
    echo "$SCRIPTNAME ERROR:Invalid profile parameters for profile '$PROFILE_ID', ICCID not set.  Bailing out"
    exit 1
fi

##
## Executing an ES2+ invocation
##
function es2plus_invoke {
    local url=$1
    local payload=$2
    local result=$(curl \
        --silent \
        --cacert "$CACERT_FILE" \
        --key "$KEY_FILE" \
        --cert  "$CERT_FILE" \
        --header "X-Admin-Protocol: gsma/rsp/v2.0.0" \
        --header "Content-Type: application/json" \
        --request POST \
        --data "$payload" \
        --insecure \
        $url)
    local statusField=$(echo $result | jq '.header.functionExecutionStatus.status')

    echo "$result"
}


##
##  Setting up a downloadOrder order parameter
##
DOWNLOAD_ORDER_PATH="/gsma/rsp2/es2plus/downloadOrder"

if [[ -z "$EID" ]]; then

    DOWNLOAD_ORDER_PAYLOAD=$(cat <<EOF
{
    "header":{
	"functionRequesterIdentifier": "${FUNCTION_REQUESTER_IDENTIFIER}",
	"functionCallIdentifier": "TX-567"},
    "iccid":"${ICCID}"
}
EOF
)

else

    DOWNLOAD_ORDER_PAYLOAD=$(cat <<EOF
{
    "header":{
	"functionRequesterIdentifier": "${FUNCTION_REQUESTER_IDENTIFIER}",
	"functionCallIdentifier": "TX-567"},
    "iccid":"${ICCID}",
    "eid":"$EID",
}
EOF
)
fi

DOWNLOAD_CMD_URL="${ES2PLUS_ENDPOINT}${DOWNLOAD_ORDER_PATH}"
DOWNLOAD_CMD_PAYLOAD=$DOWNLOAD_ORDER_PAYLOAD

##
## Sending a confirmOrder request
##

# Specifieid in section 4.1.1 (5.3.2 in the json schema)
# (SHALL consist only of upper case alphanumeric characters (0-9, A-Z) and the "-" in any combination)
# According tou or friend Rajeev in Idemia, it shall also consist only of four-character
# groups separated by dash "-" characters.
SMDS_ADDRESS="api.dev.ostelco.org"

CONFIRM_ORDER_PATH="/gsma/rsp2/es2plus/confirmOrder"
CONFIRM_ORDER_PAYLOAD=$(cat <<EOF
{
    "header":{
	"functionRequesterIdentifier": "${FUNCTION_REQUESTER_IDENTIFIER}",
	"functionCallIdentifier": "TX-568"},
    "iccid":"${ICCID}",
    "releaseFlag":true
}
EOF
)

CONFIRM_CMD_URL="${ES2PLUS_ENDPOINT}${CONFIRM_ORDER_PATH}"
CONFIRM_CMD_PAYLOAD=$CONFIRM_ORDER_PAYLOAD



##
## Sending a getProfileStatus
##

GET_PROFILE_STATUS_PATH="/gsma/rsp2/es2plus/getProfileStatus"
GET_PROFILE_STATUS_PAYLOAD=$(cat <<EOF
{
    "header":{
	"functionRequesterIdentifier": "${FUNCTION_REQUESTER_IDENTIFIER}",
	"functionCallIdentifier": "TX-568"},
    "iccidList":[{"iccid":"${ICCID}"}]
}
EOF
)

PROFILE_STATUS_CMD_URL="${ES2PLUS_ENDPOINT}${GET_PROFILE_STATUS_PATH}"
PROFILE_STATUS_CMD_PAYLOAD=$GET_PROFILE_STATUS_PAYLOAD


SMDS_ADDRESS="api.dev.ostelco.org"


##
## Sending a recoverProfiler request
##

# Specified in section 4.2.1 in Idemias M-Connect 4 documentation



RECOVER_PROFILE_PATH="/gsma/rsp2/es2plus/recoverProfile"
RECOVER_PROFILE_PAYLOAD=$(cat <<EOF
{
    "header":{
	"functionRequesterIdentifier": "${FUNCTION_REQUESTER_IDENTIFIER}",
	"functionCallIdentifier": "TX-568"},
    "iccid":"${ICCID}",
    "profileStatus": "Released"
}
EOF
)

RECOVER_CMD_URL="${ES2PLUS_ENDPOINT}${RECOVER_PROFILE_PATH}"
RECOVER_CMD_PAYLOAD=$RECOVER_PROFILE_PAYLOAD




##
## Sending a cancelProfiler request
##Es2PlusCancelOrder

# Specified in section 4.2.1 in Idemias M-Connect 4 documentation



CANCEL_ORDER_PATH="/gsma/rsp2/es2plus/cancelOrder"
CANCEL_ORDER_PAYLOAD=$(cat <<EOF
{
    "header":{
	"functionRequesterIdentifier": "${FUNCTION_REQUESTER_IDENTIFIER}",
	"functionCallIdentifier": "TX-568"},
    "iccid":"${ICCID}",
    "finalProfileStatusIndicator": "Available"
}
EOF
)

CANCEL_CMD_URL="${ES2PLUS_ENDPOINT}${CANCEL_ORDER_PATH}"
CANCEL_CMD_PAYLOAD=$CANCEL_ORDER_PAYLOAD



#
# Provision a test msisdn/imsi for esim in Loltel.
#

URL=$WG2_PROD_URL
KEY=$LOLTEL_PROD_KEY
BSSID="loltel"

function provisionMsisdn {
    local iccid=$1
    local msisdn=$2

    if [[ -z "$msisdn" ]] ; then
	echo "$SCRIPTNAME: ERROR:  Can't provision to HSS without valid msisdn"
	exit 1
    fi

    if [[ -z "$iccid" ]] ; then
	echo "$SCRIPTNAME: ERROR:  Can't provision to HSS without valid iccid"
	exit 1
    fi

    if [[ -z "$BSSID" ]] ; then
	echo "$SCRIPTNAME: ERROR:  Can't provision to HSS without valid bssid"
	exit 1
    fi

    read -r -d '' JSON << EOM
{
    "bssid": "$BSSID",
    "iccid": "$ICCID",
    "msisdn": "$MSISDN",
    "userid": "userid"
}
EOM

curl -vvv -i \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -H "x-api-key: $KEY" \
    -X POST -d "$JSON" \
    $URL
}


function strip_quotes {
    local arg=$1
    echo "$arg" | sed -e 's/^"//' -e 's/"$//'
}


###
### Do actual work
###

for CMD in $COMMANDS ; do

    if [[  "$CMD" = "es2recover" ]] ; then
        RESULT=$(es2plus_invoke "$RECOVER_CMD_URL" "$RECOVER_CMD_PAYLOAD")
	STATUS=$(strip_quotes $(echo $RESULT | jq '.header.functionExecutionStatus.status'))
	if [[  "$STATUS" = "Executed-Success" ]] ; then
	    echo "  ... $CMD Successfully reset profile"
	else
	    SUBJECT_IDENTIFIER=$(echo $RESULT | jq '.header.functionExecutionStatus.statusCodeData.subjectIdentifier')
	    ERROR_MESSAGE=$(echo $RESULT | jq '.header.functionExecutionStatus.statusCodeData.message')
            echo "$SCRIPTNAME ERROR: Command  '$CMD': $SUBJECT_IDENTIFIER, $ERROR_MESSAGE"
            exit 1
	fi
    elif [[  "$CMD" = "es2cancel" ]] ; then
        RESULT=$(es2plus_invoke "$CANCEL_CMD_URL" "$CANCEL_CMD_PAYLOAD")
	STATUS=$(strip_quotes $(echo $RESULT | jq '.header.functionExecutionStatus.status'))
	if [[  "$STATUS" = "Executed-Success" ]] ; then
	    echo "  ... $CMD Successfully cleared profile"
	else
	    SUBJECT_IDENTIFIER=$(echo $RESULT | jq '.header.functionExecutionStatus.statusCodeData.subjectIdentifier')
	    ERROR_MESSAGE=$(echo $RESULT | jq '.header.functionExecutionStatus.statusCodeData.message')
            echo "$SCRIPTNAME ERROR: Command  '$CMD': $SUBJECT_IDENTIFIER, $ERROR_MESSAGE"
            exit 1
	fi

    elif [[   "$CMD" = "es2profileStatus" ]] ; then
        RESULT=$(es2plus_invoke "$PROFILE_STATUS_CMD_URL" "$PROFILE_STATUS_CMD_PAYLOAD")
	STATUS=$(strip_quotes $(echo $RESULT | jq '.header.functionExecutionStatus.status'))
        echo "result = $RESULT"
	if [[  "$STATUS" = "Executed-Success" ]] ; then
	    AC_TOKEN=$(strip_quotes $(echo $RESULT | jq '.profileStatusList[0].acToken'))
	    STATE=$(strip_quotes $(echo $RESULT | jq '.profileStatusList[0].state'))
	    EID=$(strip_quotes $(echo $RESULT | jq '.profileStatusList[0].eid'))
	    QR="LPA:1\$rsp-0002.oberthur.net\$$AC_TOKEN"
	    echo "  $CMD Successfully downloaded profile state (ICCID, STATE, AC_TOKEN): $ICCID, $STATE, $AC_TOKEN"
	else
	    SUBJECT_IDENTIFIER=$(echo $RESULT | jq '.header.functionExecutionStatus.statusCodeData.subjectIdentifier')
	    ERROR_MESSAGE=$(echo $RESULT | jq '.header.functionExecutionStatus.statusCodeData.message')
            echo "$SCRIPTNAME ERROR: Command  '$CMD': $SUBJECT_IDENTIFIER, $ERROR_MESSAGE"
            exit 1
	fi

    elif [[  "$CMD" = "es2download"  ]] ; then
        es2plus_invoke "$DOWNLOAD_CMD_URL" "$DOWNLOAD_CMD_PAYLOAD"
    elif [[  "$CMD" = "es2confirm"  ]] ; then
        es2plus_invoke "$CONFIRM_CMD_URL" "$CONFIRM_CMD_PAYLOAD"
    elif [[  "$CMD" = "hlrProvision" ]] ; then
	echo "hlrProvision not implemented for production"
	exit 1
    else
        echo "$SCRIPTNAME ERROR: Unknown command '$CMD'. Legal commands are es2recover, es2download, es2confirm, es2ProfileStatus and hlrovision. "
        exit 1
    fi
done

##
## Print what is known about the profile
##


echo "Known data or best guess about profile"
echo "PROFILE_ID=$PROFILE_ID"
echo "PROFILE_STATUS=$PROFILE_STATUS"
echo "PROFILE_NICKNAME=$PROFILE_NICKNAME"
echo "ICCID=$ICCID"
echo "IMSI=$IMSI"
echo "EID=$EID"
echo "MSISDN=$MSISDN"
echo "QR=$QR"
