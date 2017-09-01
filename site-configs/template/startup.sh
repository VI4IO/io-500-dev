#!/bin/bash
#SBATCH --ntasks-per-node=10
#SBATCH --nodes=100
#SBATCH --job-name=IO-500
#SBATCH --time=02:50:00
#SBATCH -o io_500_out_%J
#SBATCH -e io_500_err_%J

# Command to start an MPI application
mpirun="srun -m block"
mpirun_pfind=$mpirun
workdir= # directory where the data will be stored
output_dir= # the directory where the output will be kept

# Tunable parameters, feel free to change them
# The write phase for each benchmark (ior_easy, ior_hard, mdtest_easy, mdtest_hard) must be 5 minutes
ior_easy_params="-t 2048k -b 122880000k" # 120 GBytes per process, file per proc is already configured
ior_hard_writes_per_proc=5000               # each process writes 5000 times 47k
mdtest_hard_files_per_proc=6000
mdtest_easy_files_per_proc=6000
# If to use mdreal
params_mdreal="-P=5000 -I=1000"
subtree_to_scan_config=$PWD/subtree.cfg
processes_find=100 
# If you use the find command from find/io500-find.sh, you can specify how many directories to scan to limit its runtime
# Here scan 100 dirs
# The subtrees to scan from md-easy, each contains mdtest_easy_files_per_proc files
( for I in $(seq $processes_find) ; do
  echo mdtest_tree.$I.0
done ) > subtree.cfg

# Define the executables for the commands
#Parallel find
#find_cmd=$PWD/../../find/pfind/io500-pfind.sh
#To execute parallel find uncomment both lines below
#run_pfind="True"
#run_find="False"
#Serialized find
find_cmd=$PWD/../../find/io500-find.sh
ior_cmd=/home/dkrz/k202079/work/io-500/io-500-dev/proposal-draft/ior
mdtest_cmd=/home/dkrz/k202079/work/io-500/io-500-dev/proposal-draft/mdtest
# if set != "" then run mdreal
mdreal_cmd=

lines=`wc -l < subtree.cfg`
if [ $lines -le $SLURM_JOB_NUM_NODES ];
then
        mpirun_pfind=$mpirun" --ntasks-per-node=1"
fi
# Add whatever you want to do for preparing the workdirectory
# Here we precreate directories for lustre with the appropriate striping
mkdir -p ${workdir}/ior_easy
lfs setstripe --stripe-count 2  ${workdir}/ior_easy

mkdir -p ${workdir}/ior_hard
lfs setstripe --stripe-count 100  ${workdir}/ior_hard

# Now write the output/results  file
(
cd ../../ # walk to the directory with the io_500_core script

# Add key/value pairs defining your system if you want
echo "filesystem_utilization=$(df /mnt/lustre02)"
echo "date=$(date -I)"
echo "queue="
echo "nodes=$SLURM_NNODES"
echo "ppn=$SLURM_TASKS_PER_NODE"
echo "nodelist=$SLURM_NODELIST"

# Important: source the io 500 script:
source io_500_core.sh # Do not change the script
) 2>&1 | tee $SLURM_NNODES.txt

# Cleanup some leftovers
rm -rf $workdir/
