#!/bin/bash

# Generate a list of SQL update statements that should be run directly against the
# sim database to update it with respect to activation codes from
# the sm-dp+

# Process the ICCIds
input="iccid-confirmation-codes.csv"

if [[ ! -f "$input" ]] ; then
    echo "Could not find input iccid/activartion code file $input"
    exit 1
fi 


while IFS= read -r iccidMatchingIdLine
do
  iccid=$(echo $iccidMatchingIdLine | awk '{print $1}')
  matchingid=$(echo $iccidMatchingIdLine | awk '{print $2}')
  echo "UPDATE sim_entries SET matchingid = '$matchingid', smdpplusstate = 'RELEASED', provisionedState = 'AVAILABLE' WHERE iccid = '$iccid' and smdpplusstate = 'AVAILABLE';"
done < "$input"




