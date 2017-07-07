#!/bin/bash
#SBATCH --ntasks-per-node=6
#SBATCH --nodes=10
#SBATCH --job-name=IO-500
#SBATCH --time=02:50:00
#SBATCH -o io_500_out_%J
#SBATCH -e io_500_err_%J

module load bullxmpi
module load intel

# set here the parameters you want
nodes=$SLURM_JOB_NUM_NODES

mpirun="srun -N $nodes -n $SLURM_NTASKS"
workdir=$PWD/io500/data
output_dir=$PWD/io500/results
ior_easy_params="-t 2048k -b 2048000k" # 2 GBytes per process, file per proc is already configured
ior_hard_writes_per_proc=1000               # each process writes 1000 times 47k
mdtest_hard_files_per_proc=1000           
mdtest_easy_files_per_proc=1000

# commands
find_cmd=$PWD/io500-find.sh
ior_cmd=/home/dkrz/k202079/work/io-500/io-500-dev/proposal-draft/ior
mdtest_cmd=/home/dkrz/k202079/work/io-500/io-500-dev/proposal-draft/mdtest

(
source io_500_core.sh
) 2>&1 | tee $nodes-$SLURM_NTASKS.txt

rm -rf $workdir
