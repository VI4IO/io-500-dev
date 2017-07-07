#!/bin/bash
# feel free to replace this command with another command
# Input arguments is the workdir
# Expected output is the number of found entities divided by the runtime, e.g., ioops for the found entities
timestamp=$1
workdir=$2

start=$(date +%s.%N)
found=$(find ${workdir} -name \*.0.\* -newer $timestamp  -size +3000c | wc -l)
end=$(date +%s.%N)
export duration=$(echo "scale=2; $end - $start" | bc)

echo "$found/$duration" |bc

