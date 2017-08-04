#!/bin/bash 
#SBATCH --ntasks-per-node=8
#SBATCH --partition=workq
#SBATCH --nodes=300
#SBATCH --job-name=IO-500
#SBATCH --time=02:30:00
#SBATCH -o io_500_out_%J
#SBATCH -e io_500_err_%J

#DW jobdw type=scratch access_mode=striped capacity=500000GiB

# parameters that are always true
# If hyperthreading is not active, do not divide by two in the next command
let maxTasks=$((${SLURM_NTASKS_PER_NODE} * ${SLURM_JOB_NUM_NODES}))/2
mpirun="srun -m block"
workdir=/$DW_JOB_STRIPED/test.$$/
output_dir=/project/k01/markomg/bb_io500-results-${SLURM_JOB_NUM_NODES}.$$

#params_mdreal="-P=5000 -I=1000"
  subtree_to_scan_config=$PWD/subtree.cfg
  
  # The subtrees to scan from md-easy, each contains mdtest_easy_files_per_proc files
  ( for I in $(seq 200) ; do 
    echo mdtest_tree.$I.0
  done ) > subtree.cfg
 cp subtree.cfg ../
# ToDo add here optimum values
ior_easy_params="-t 2m -b 192616m"
ior_hard_writes_per_proc=77872
mdtest_hard_files_per_proc=1630
mdtest_easy_files_per_proc=10800

# precreate directories for lustre with the appropriate striping
mkdir -p ${workdir}/ior_easy

mkdir -p ${workdir}/ior_hard

#To execute parallel find uncomment both lines below
#run_pfind="True"
#run_find="False"

# commands
#Parallel find
#find_cmd=$PWD/../io500-pfind.sh
#Serialized find
find_cmd=$PWD/../io500-find.sh

ior_cmd=/project/k01/markomg/burst_test/BB_ior/io-500-dev/proposal-draft/ior
mdtest_cmd=/project/k01/markomg/burst_test/BB_ior/io-500-dev/proposal-draft/mdtest
mdreal_cmd=/project/k01/markomg/burst_test/BB_ior/io-500-dev/proposal-draft/md-real-io # set to "" to not run mdreal

params_mdreal="-P=1000 -I=100"

echo "System statistics"
echo "Number of running jobs: "`squeue -t running | wc -l`
echo "Number of nodes of largest job: "`squeue | grep -v NODES | awk 'BEGIN{proc=0}{if($NF>proc) proc=$NF}END{print proc}'
`


(
cd ..
source io_500_core.sh
) 2>&1 | tee $SLURM_NNODES.txt

rm -rf $workdir/
