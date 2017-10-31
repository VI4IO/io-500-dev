#!/bin/bash
#SBATCH --ntasks-per-node=10
#SBATCH --nodes=100
#SBATCH --job-name=IO-500
#SBATCH --time=07:50:00
#SBATCH -o io_500_out_%J
#SBATCH -e io_500_err_%J
#SBATCH --dependency=singleton

module load intel mxm/3.4.3082 fca/2.5.2431 bullxmpi_mlx/bullxmpi_mlx-1.2.9.2 cmake/3.2.3 gcc/7.1.0

dir=/home/dkrz/k202079/work/io-500/io500-app
stamp=$(date | sed "s/ //g" | sed "s/:/-/g")
workdir=/mnt/lustre02/work/k20200/k202079/io500/data
resdir=$dir/res-${SLURM_NNODES}-${SLURM_NPROCS}-$stamp

srun --propagate=STACK $dir/io500 -w $workdir -C
rm -rf $workdir

workdir=/mnt/lustre02/work/k20200/k202079/io500/data-$stamp

# precreate directories for lustre with the appropriate striping
mkdir -p ${workdir}/ior_easy
lfs setstripe --stripe-count 2  ${workdir}/ior_easy

mkdir -p ${workdir}/ior_hard
lfs setstripe --stripe-count 200  ${workdir}/ior_hard

ulimit -s 102400
srun --propagate=STACK $dir/io500 -w $workdir -r $resdir -s 300 -S -v -f 20000 -F 20000 -I 15000 -e "-F -t 1m -b 128g"
