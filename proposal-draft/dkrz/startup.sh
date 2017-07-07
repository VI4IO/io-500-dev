#!/bin/bash
#SBATCH --ntasks-per-node=6
#SBATCH --nodes=10
#SBATCH --job-name=IO-500
#SBATCH --time=00:50:00
#SBATCH -o io_500_out_%J
#SBATCH -e io_500_err_%J

module load bullxmpi
module load intel

# set here the parameters you want

nodes=$SLURM_JOB_NUM_NODES
procs_per_node=$SLURM_JOB_CPUS_PER_NODE

mpirun="srun -N $nodes --ntasks-per-node=${procs_per_node}"
workdir=$PWD/io500/data
output_dir=$PWD/io500/results
ior_easy_params="-t 2048k -b 2048000k"
ior_hard_writes_per_proc=5
mdtest_hard_files_per_proc=1
mdtest_easy_files_per_proc=2

# commands
find_cmd=$PWD/io500-find.sh
ior_cmd=/home/dkrz/k202079/work/io-500/io-500-dev/proposal-draft/ior
mdtest_cmd=/home/dkrz/k202079/work/io-500/io-500-dev/proposal-draft/mdtest

source io_500_core.sh

# rm -rf $workdir
