#! /bin/bash

searchdir=$1
timestamp_file=$2
target_size=$3
target_string=$4

# also an environment variable is set containing $IO500_MPI
# which contains any values for $io500_mpirun and $io500_mpiargs set in io500.sh

# feel free to edit this file as much as you want (e.g. change how MPI is launched).
# if you do so, please just document and report the change in your submission.

pfind=`dirname $0`/pfind          # ensure that the git repo has been cloned

if [ -x "$pfind" ] ; then
  $IO500_MPI $pfind -newer $timestamp_file -name "$target_string" -size $target_size -silent $searchdir 
else
  echo "ERROR: $pfind not found; Need to install pfind.py from pwalk github repo"
fi
