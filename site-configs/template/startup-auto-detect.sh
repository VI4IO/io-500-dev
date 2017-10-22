#!/bin/bash -x
# This testscript illustrates how to debug (uses -x flag) and uses the auto detection of parameters for the IO 500 main testing script
# Thus, it helps to identify suitable parameters for the write/creation phases
# The header contains the SLURM setup to run on 10 nodes with 10 takss per node
# Change it to whatever is necessary.
#SBATCH --ntasks-per-node=10
#SBATCH --nodes=10
#SBATCH --job-name=IO-500
#SBATCH --time=02:50:00
#SBATCH -d singleton
#SBATCH -o io_500_out_%J
#SBATCH -e io_500_err_%J

# Set global parameters that shall be used (see also startup.sh)
maxTasks=$((${SLURM_JOB_CPUS_PER_NODE} * ${SLURM_JOB_NUM_NODES}))
mpirun="srun -m block"
# Set the work directory, i.e., where the I/O is done
workdir=/mnt/lustre02/work/k20200/k202079/io500-data/
# The output directory containing intermediate results (also useful for debugging)
output_dir=/mnt/lustre02/work/k20200/k202079/io500-results-${SLURM_JOB_NUM_NODES}


# Set commands to use
find_cmd=$PWD/../../find/io500-find.sh
ior_cmd=/home/dkrz/k202079/work/io-500/io-500-dev/proposal-draft/ior
mdtest_cmd=/home/dkrz/k202079/work/io-500/io-500-dev/proposal-draft/mdtest
#mdreal_cmd=/home/dkrz/k202079/work/io-500/io-500-dev/proposal-draft/md-real-io # set to "" to not run mdreal

# You may turn off the automatic determination of parameters individually
identify_parameters_ior_hard=True
identify_parameters_ior_easy=True
identify_parameters_md_easy=True # also allows to do the find
identify_parameters_md_hard=True
identify_parameters_find=False # only works if ior_easy is also run

# Time in seconds that the benchmark shall be run at least (expected 500s)
# But you can use less and scale up manually to speed up the testing
timeExpected=10


# Optional step: Preparation of the work directory
# Here: precreate directories for lustre with the appropriate striping
mkdir -p ${workdir}/ior_easy
lfs setstripe --stripe-count 2  ${workdir}/ior_easy

mkdir -p ${workdir}/ior_hard
lfs setstripe --stripe-count 100  ${workdir}/ior_hard
##########

cd ../../
# Run the script to explore parameters
source ./utilities/auto-determine-parameters.sh | tee auto-${SLURM_JOB_NUM_NODES}-${SLURM_JOB_CPUS_PER_NODE}.txt
