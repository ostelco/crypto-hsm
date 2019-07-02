#!/bin/bash


let "current = 1000"
let "last = 10000"
let "stride = 100"

while [[ $current -lt  $last ]] ; do
  let "lower = $current + 1 "
  let "upper = $current + $stride"
  ./process-iccids.sh $lower $upper iccid-list.txt > iccid-confirmation-codes-$lower-$upper.csv &
  let "current = $upper"
done