#!/bin/bash
#SBATCH --ntasks-per-node=10
#SBATCH --nodes=100
#SBATCH --job-name=IO-500
#SBATCH --time=02:50:00
#SBATCH -o io_500_out_%J
#SBATCH -e io_500_err_%J

module load bullxmpi
module load intel

# choosing parameters for DKRZ
# throughput for independent I/O ~400 GByte/s => 300*400 == 120 TByte data to write or 120 GByte per process...
# IOPS for random I/O (1500 IOPS per client): 5000
# metadata: 20k Ops for a single MD server (here we use only one albeit we have 5+8) => 300*20k / 10000 = 6000
# find: roughly 12 seconds to scan a 6000 file directory => 25 directories => this can be parallelized, say 10x improvement

mpirun="srun -m block"
workdir=/mnt/lustre02/work/k20200/k202079/io500/data
output_dir=/mnt/lustre02/work/k20200/k202079/io500/results
ior_easy_params="-t 2048k -b 122880000k" # 120 GBytes per process, file per proc is already configured
ior_hard_writes_per_proc=5000               # each process writes 1000 times 47k
mdtest_hard_files_per_proc=6000
mdtest_easy_files_per_proc=6000

#params_mdreal="-P=5000 -I=1000"
subtree_to_scan_config=$PWD/subtree.cfg

# The subtrees to scan from md-easy, each contains mdtest_easy_files_per_proc files
( for I in $(seq 100) ; do
  echo mdtest_tree.$I.0
done ) > subtree.cfg

# commands
find_cmd=$PWD/../../find/io500-find.sh
ior_cmd=/home/dkrz/k202079/work/io-500/io-500-dev/proposal-draft/ior
mdtest_cmd=/home/dkrz/k202079/work/io-500/io-500-dev/proposal-draft/mdtest
#mdreal_cmd=/home/dkrz/k202079/work/io-500/io-500-dev/proposal-draft/md-real-io # if set != "" then run mdreal

# precreate directories for lustre with the appropriate striping
mkdir -p ${workdir}/ior_easy
lfs setstripe --stripe-count 2  ${workdir}/ior_easy

mkdir -p ${workdir}/ior_hard
lfs setstripe --stripe-count 100  ${workdir}/ior_hard

(
cd ..
echo "filesystem_utilization=$(df /mnt/lustre02)"
echo "date=$(date -I)"
echo "queue="
echo "nodes=$SLURM_NNODES"
echo "ppn=$SLURM_TASKS_PER_NODE"
echo "nodelist=$SLURM_NODELIST"

source io_500_core.sh
) 2>&1 | tee $SLURM_NNODES.txt

rm -rf $workdir/
