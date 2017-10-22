#!/bin/bash
# feel free to replace this command with another command
# Input arguments is the workdir
# Expected output is the number of found entities divided by the runtime, e.g., ioops for the found entities
# When using the io500-find.sh script use typically 2x the number of logical machine cores to get best performance
timestamp=$1
workdir="$2"
subtree_to_scan_config="$3"

# unfortunately this script has been deprecated.
# we need a better default find that we currently have.
# hopefully someone creates one.
# when you do, please use the required input/output as described in ./io500_find.sh

start=$(date +%s.%N)
C=0
# trivial parallelism of the find command across the directories
for DIR in $(cat $subtree_to_scan_config); do 
	C=$(($C+1))
	find ${workdir}/$DIR -name \*.mdtest.\* -newer $timestamp  -size 0c | wc -l > $workdir/find-$C &
done

wait

found=0
C=0
# trivial parallelism
for DIR in $(cat $subtree_to_scan_config); do 
	C=$(($C+1))
	found=$(($found+ $(cat $workdir/find-$C)))
	rm $workdir/find-$C
done

end=$(date +%s.%N)
export duration=$(echo "scale=2; $end - $start" | bc)

echo "$found/$duration" |bc

