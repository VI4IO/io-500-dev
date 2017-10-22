#! /bin/bash

searchdir=$1
timestamp_file=$2
target_size=$3

# also an environment variable is set containing $IO500_MPI
# which contains any values for $io500_mpirun and $io500_mpiargs set in io500.sh

# others will need to change gstat to stat.  Stupid mac issue.
timestamp=`gstat -c %Y $timestamp_file`
pfind=`dirname $0`/pwalk/pfind.py

if [ -x "$pfind" ] ; then
  $IO500_MPI $pfind -newer $timestamp -name "01" -size $target_size -silent $searchdir 
else
  echo "ERROR: Need to install pfind.py from pwalk github repo"
fi
