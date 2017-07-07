#!/bin/bash -e
workdir=$1

start=$(date +%s.%N)
found=$(find ${workdir} -name \*.0.\* -newer ${workdir}/timestamp  -size +3000c | wc -l)
end=$(date +%s.%N)
export duration=$(echo "scale=2; $end - $start" | bc)

echo "$found/$duration" |bc

