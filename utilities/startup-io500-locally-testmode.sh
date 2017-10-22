#!/bin/bash
echo This script runs a single process through all IO500 benchmarks

if [[ ! -e $PWD/io_500_core.sh ]] ; then
  echo This script shall be executed from the root directory of io-500-dev
  exit 1
fi

# Command to start an MPI application, not needed, single process
mpirun=""
workdir=$PWD/workdir # directory where the data will be stored
output_dir=$PWD/workdir-results # the directory where the output will be kept

# Tunable parameters, feel free to change them
# The write phase for each benchmark (ior_easy, ior_hard, mdtest_easy, mdtest_hard) must be 5 minutes
ior_easy_params="-t 2m -b 20m" # write 20 MByte
ior_hard_writes_per_proc=50 # each process writes 5000 times 47k
mdtest_hard_files_per_proc=60
mdtest_easy_files_per_proc=60
# If to use mdreal
params_mdreal="-P=50 -I=10"
subtree_to_scan_config=$PWD/workdir/subtree.cfg

mkdir $workdir 2>/dev/null

# If you use the find command from find/io500-find.sh, you can specify how many directories to scan to limit its runtime
# Here scan 1 dirs
# The subtrees to scan from md-easy, each contains mdtest_easy_files_per_proc files
( for I in $(seq 0 0) ; do
  echo mdtest_tree.$I.0
done ) > $workdir/subtree.cfg

# Define the executables for the commands
find_cmd=$PWD/utilities/find/io500-find.sh
ior_cmd=$PWD/bin/ior
mdtest_cmd=$PWD/bin/mdtest
mdreal_cmd=$PWD/bin/md-real-io # if set != "" then run mdreal


# Add whatever you want to do for preparing the workdirectory
# Here we do nothing ...
#### DO STH ELSE

# Now write the output/results  file
(
cd . # walk to the directory with the io_500_core script, here not needed

# Add key/value pairs defining your system if you want
echo "date=$(date -I)"
echo "nodes=1"
echo "ppn=1"
echo "nodelist=$(hostname)"

# Important: source the io 500 script:
source io_500_core.sh # Do not change the script
) 2>&1 | tee results-local.txt

# Cleanup some leftovers
rm -rf $workdir/
