#!/bin/bash

#  Dependencies
GEN=/Users/rmz/git/ostelco-core/sim-administration/utils/upload-sim-batch.go
PREPRODUCTION=http://preproduction/
PRODUCTION=http://production/

# Put the files in a directory called "result"
rm -rf result
mkdir result
cd result

# Generating the batch importer files

# Pre-production
# $GEN -first-iccid 896503011904000006 -last-iccid 896503011904000007 -first-imsi 525038763000002 -last-imsi 525038763000003 -first-msisdn 6588650003 -last-msisdn 6588650004 -profile-type OYA_M1_BF76 > import-batch2.sh
# $GEN -first-iccid 896503011905140000 -last-iccid 896503011905140199 -first-imsi 525038763000004 -last-imsi 525038763000203 -first-msisdn 6588650005 -last-msisdn 6588650204 -profile-type OYA_M1_STANDARD  > import-batch3.sh
# $GEN -first-iccid 896503011905140208 -last-iccid 896503011905140407 -first-imsi 525038763000208 -last-imsi 525038763000407 -first-msisdn 6588650209 -last-msisdn 6588650408 -profile-type OYA_M1_BF76  > import-batch4.sh


## Production

# .. four 
$GEN -first-iccid 896503011905140204 -last-iccid 896503011905140207 -first-imsi 525038763000204 -last-imsi 525038763000207 -first-msisdn 6588650205 -last-msisdn 6588650208 -profile-type OYA_M1_STANDARD > import-batch5.sh


# the first  95086 of the ten thousand
$GEN -first-iccid 896503011906010000 -last-iccid 896503011906019585 -first-imsi 525038763000412 -last-imsi 525038763009997 -first-msisdn 6588650413 -last-msisdn 6588659998 -profile-type OYA_M1_STANDARD > import-batch6.sh


# The final 414 of the ten thousand
$GEN -first-iccid 896503011906019586 -last-iccid 896503011906019999  -first-imsi 525038763009998 -last-imsi 525038763010411  -first-msisdn 6588670000 -last-msisdn 6588670413 -profile-type OYA_M1_STANDARD > import-batch7.sh
 



# Make them all executable

# chmod +x import-batch2.sh
# chmod +x import-batch3.sh
# chmod +x import-batch4.sh

chmod +x import-batch5.sh import-batch6.sh  import-batch7.sh

rm -f iccids.txt
for x in import-batch6.sh import-batch7.sh ; do 
    awk -F, -f ../extract-non-golden-msisdns.awk   $x  >> iccids.txt
done


