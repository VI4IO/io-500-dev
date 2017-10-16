#!/bin/bash
#
# INSTRUCTIONS:
# Edit the 6 steps below as needed for your machine
#
# 1. Set the nodes, tasks per node, and time to work for the job (may take
#    some fiddling).
#
#SBATCH --account=FY140262
#SBATCH --ntasks-per-node=10
#SBATCH --nodes=10
#SBATCH --job-name=IO-500
#SBATCH --time=00:20:00
#SBATCH -o io_500_out_%J
#SBATCH -e io_500_err_%J

#
# 2. change the directories for filesys_root, workdir, and output_dir
filesys_root=/fscratch
#filesys_root=/gscratch
#filesys_root=/gpfs1
workdir=${filesys_root}/gflofst/io500 # directory where the data will be stored
output_dir=${filesys_root}/gflofst/results  # the directory where the output will be kept
#
# 3. set command to run MPI
# Command to start an MPI application
mpirun="srun -m block --mpi=pmi2 "
mpirun_pfind=$mpirun
#
# 4. Set the different commands to run
# Define the executables for the commands
#Parallel find
#find_cmd=$PWD/../../find/pfind/io500-pfind.sh
#To execute parallel find uncomment both lines below
#run_pfind="True"
#run_find="False"
#Serialized find
#find_cmd=$PWD/../../find/io500-find.sh
find_cmd=find
ior_cmd=${workdir}/ior
mdtest_cmd=${workdir}/mdtest
# if set != "" then run mdreal
mdreal_cmd=${workdir}/md-real-io

#
# 5. Set the tunable parameters (easy, hard, and directories to use)
#    Also set the directory parameters (Lustre). Each of these must enable it
#    to run for more than 5 minutes.
#
# Tunable parameters, feel free to change them
# The write phase for each benchmark (ior_easy, ior_hard, mdtest_easy, mdtest_hard) must be 5 minutes
#ior_easy_params="-t 2048k -b 122880000k" # 120 GBytes per process, file per proc is already configured
ior_easy_params="-t 2048k -b 20g" # file per proc is already configured
ior_hard_writes_per_proc=6000     
mdtest_easy_files_per_proc=61000  
mdtest_hard_files_per_proc=61000
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
lfs setstripe --stripe-count 100  ${workdir}/ior_hard

#
# 6. Run the core script
#
# Now write the output/results  file
(
#cd ../../ # walk to the directory with the io_500_core script

# Add key/value pairs defining your system if you want
echo "System: " `uname -n`
echo "filesystem_utilization=$(df ${filesys_root})"
echo "date=$(date -I)"
echo "queue="
echo "nodes=$SLURM_NNODES"
echo "ppn=$SLURM_TASKS_PER_NODE"
echo "nodelist=$SLURM_NODELIST"
echo "workdir=$workdir"
echo "output_dir=$output_dir"
echo "filesys_root=$filesys_root"
echo "find_cmd=$find"
echo "ior_cmd=$ior_cmd"
echo "mdtest_cmd=$mdtest_cmd"
echo "mdreal_cmd=$mdreal_cmd"
echo "ior_easy_params=$ior_easy_params"
echo "ior_hard_write_per_proc=$io_hard_writes_per_proc"
echo "mdtest_easy_files_per_proc=$mdtest_easy_files_per_proc"
echo "mdtest_hard_files_per_proc=$mdtest_hard_files_per_proc"
echo "mdreal_params=$mdreal_params"

# Important: source the io 500 script:
source io_500_core.sh # Do not change the script
) 2>&1 | tee $SLURM_NNODES.txt

# Cleanup some leftovers
rm -rf $workdir/
