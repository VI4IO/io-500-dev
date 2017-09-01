#!/bin/bash -e
#SBATCH --ntasks-per-node=16
#SBATCH --partition=workq
#SBATCH --nodes=1000
#SBATCH --job-name=IO-500
#SBATCH --time=02:30:00
#SBATCH -o io_500_out_%J
#SBATCH -e io_500_err_%J


# parameters that are always true
# If hyperthreading is not active, do not divide by two in the next command
let maxTasks=$((${SLURM_NTASKS_PER_NODE} * ${SLURM_JOB_NUM_NODES}))/2
mpirun="srun -m block --hint=nomultithread"
mpirun_pfind=$mpirun
workdir=/project/k01/markomg/test.$$/
output_dir=/project/k01/markomg/io500-results-${SLURM_JOB_NUM_NODES}.$$


ior_easy_params="-t 2m -b 5440m"
ior_hard_writes_per_proc=792
mdtest_easy_files_per_proc=380
mdtest_hard_files_per_proc=452



params_mdreal="-P=1000 -I=100"
subtree_to_scan_config=$PWD/subtree.cfg
processes_find=6000

  # The subtrees to scan from md-easy, each contains mdtest_easy_files_per_proc files
  ( for I in $(seq $processes_find) ; do
    echo mdtest_tree.$I.0
  done ) > subtree.cfg


 cp subtree.cfg ../../

  lines=`wc -l < subtree.cfg`

if [ $lines -le $SLURM_JOB_NUM_NODES ];
then
        mpirun_pfind=$mpirun" --ntasks-per-node=1"
fi


# precreate directories for lustre with the appropriate striping
mkdir -p ${workdir}/ior_easy
lfs setstripe --stripe-count 2  ${workdir}/ior_easy

mkdir -p ${workdir}/ior_hard
lfs setstripe --stripe-count 144  ${workdir}/ior_hard



# commands
#Parallel find
find_cmd=$PWD/../../find/pfind/io500-pfind.sh
#Serialized find
#find_cmd=$PWD/../../find/io500-find.sh

#To execute parallel find uncomment both lines below
run_pfind="True"
run_find="False"

ior_cmd=/project/k01/markomg/burst_test/BB_ior/io-500-dev/proposal-draft/ior
mdtest_cmd=/project/k01/markomg/burst_test/BB_ior/io-500-dev/proposal-draft/mdtest
mdreal_cmd=/project/k01/markomg/burst_test/BB_ior/io-500-dev/proposal-draft/md-real-io # set to "" to not run mdreal



(
cd ../../
source io_500_core.sh
) 2>&1 | tee $SLURM_NNODES.txt

rm -rf $workdir/
