#!/bin/bash

# First and last of the ICCID file that will be processed
first=1
last=3

let "current = 1"

# Process the ICCIds
input="iccid-list.txt"
while IFS= read -r iccid
do

  if [[ $first -le  $current ]] ; then
      if [[ $current -le $last ]] ; then
	  status=$(./update-profile.sh iccid $iccid es2profileStatus | grep es2profileStatus | awk -F: '{print $2}' | awk -F, '{print $2}' | sed 's/ *//g') 
	  if [[ "AVAILABLE" == "$status" ]] ; then
	      ./update-profile.sh iccid $iccid es2download es2confirm es2profileStatus | awk -F: '{print $2}' | awk -F, '{print $1, $3}'
	  else
	      ./update-profile.sh iccid $iccid es2download |  es2profileStatus | awk -F: '{print $2}' | awk -F, '{print $1, $3}'
	  fi
      fi
  fi
  
  let "current = $current + 1"
done < "$input"
