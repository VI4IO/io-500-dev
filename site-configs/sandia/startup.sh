#!/bin/bash
#
# INSTRUCTIONS:
# Edit the 7 steps below as needed for your machine
#
# 1. Set the nodes, tasks per node, and time to work for the job (may take
#    some fiddling).
#
#SBATCH --account=FY140262
#SBATCH --ntasks-per-node=10
#SBATCH --nodes=16
#SBATCH --job-name=IO-500
#SBATCH --time=00:40:00
#SBATCH -o io_500_out_%J
#SBATCH -e io_500_err_%J

#
# 2. change the directories for filesys_root, workdir, and result_dir
filesys_root=/fscratch
#filesys_root=/gscratch
#filesys_root=/gpfs1
basedir=${filesys_root}/gflofst
workdir=${basedir}/io500.`date +%Y.%m.%d-%H.%M.%S` # directory where the data will be stored
result_dir=${basedir}/results.`date +%Y.%m.%d-%H.%M.%S`  # the directory where the output will be kept
mkdir -p $workdir
mkdir -p $result_dir

#
# 3. set command to run MPI
# Command to start an MPI application
mpirun="srun -m block --mpi=pmi2 "
mpirun_pfind=$mpirun
#
# 4. Set the different commands to run
ior_cmd=${basedir}/ior
mdtest_cmd=${basedir}/mdtest
# if set != "" then run mdreal
mdreal_cmd=${basedir}/md-real-io

#
# 5. setup the find command. This is an area where innovation is allowed.
#    There are two default options provided. One is a serial find and the other
#    is a parallel version. If neither of these is used. The source code for
#    the alternative version must be provided along with building scripts and
#    proper runtime parameters and setup commands.
#Parallel find
#find_cmd=$PWD/../../find/pfind/io500-pfind.sh
#To execute parallel find uncomment both lines below
#run_pfind="True"
#run_find="False"
#Serialized find
find_cmd=${basedir}/io500-find.sh

#
# 6. Set the tunable parameters (easy, hard, and directories to use)
#    Also set the directory parameters (Lustre). Each of these must enable it
#    to run for more than 5 minutes.
#
# Tunable parameters, feel free to change them
# The write phase for each benchmark (ior_easy, ior_hard, mdtest_easy, mdtest_hard) must be 5 minutes
#ior_easy_params="-t 2048k -b 122880000k" # 120 GBytes per process, file per proc is already configured
#define QUICK_RUN 0
#if QUICK_RUN
ior_easy_params="-t 2048k -b 2g" # file per proc is already configured
ior_hard_writes_per_proc=60
mdtest_easy_files_per_proc=6100
mdtest_hard_files_per_proc=6100
#else
ior_easy_params="-t 2048k -b 20g" # file per proc is already configured
ior_hard_writes_per_proc=7000     
mdtest_easy_files_per_proc=25000
mdtest_hard_files_per_proc=25000
#endif
# If to use mdreal
mdreal_params="-P=5000 -I=1000"
find_subtree_to_scan_config=$PWD/find_subtree.cfg
processes_find=100 
# If you use the find command from find/io500-find.sh, you can specify how many directories to scan to limit its runtime
# Here scan 100 dirs
# The subtrees to scan from md-easy, each contains mdtest_easy_files_per_proc files
( for I in $(seq $processes_find) ; do
  echo mdtest_tree.$I.0
done ) > find_subtree.cfg

lines=`wc -l < find_subtree.cfg`
if [ $lines -le $SLURM_JOB_NUM_NODES ];
then
        mpirun_pfind=$mpirun" --ntasks-per-node=1"
fi
# Add whatever you want to do for preparing the workdirectory
# Here we precreate directories for lustre with the appropriate striping
mkdir -p ${workdir}/ior_easy
lfs setstripe --stripe-count 2  ${workdir}/ior_easy

mkdir -p ${workdir}/ior_hard
let "total_stripes = ${SLRUM_NNODES} * ${SLURM_TASKS_PER_NODE}"
# alternatively, make this the number of storage targets
lfs setstripe --stripe-count ${total_stripes} ${workdir}/ior_hard

#
# 7. Run the core script
#
# Now write the output/results  file
(
#cd ../../ # walk to the directory with the io_500_core script

# Add key/value pairs defining your system if you want
echo Started at `date +%Y.%m.%d-%H.%M.%S`
echo "System: " `uname -n`
echo "filesystem_utilization=$(df ${filesys_root})"
echo "date=$(date -I)"
#echo "queue="
echo "nodes=$SLURM_NNODES"
echo "ppn=$SLURM_TASKS_PER_NODE"
echo "nodelist=$SLURM_NODELIST"
echo "workdir=$workdir"
echo "result_dir=$result_dir"
echo "filesys_root=$filesys_root"
echo "find_cmd=$find_cmd"
echo "ior_cmd=$ior_cmd"
echo "mdtest_cmd=$mdtest_cmd"
echo "mdreal_cmd=$mdreal_cmd"
echo "ior_easy_params=$ior_easy_params"
echo "ior_hard_writes_per_proc=$ior_hard_writes_per_proc"
echo "mdtest_easy_files_per_proc=$mdtest_easy_files_per_proc"
echo "mdtest_hard_files_per_proc=$mdtest_hard_files_per_proc"
echo "mdreal_params=$mdreal_params"

# Important: source the io 500 script:
source io_500_core.sh # Do not change the script
) 2>&1 | tee io-500-summary.`date +%Y.%m.%d-%H.%M.%S`.txt

# Cleanup
rmdir $workdir
rm -f find_subtree.cfg

# Give a completion time
echo Finished at `date +%Y.%m.%d-%H.%M.%S`
