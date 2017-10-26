#!/bin/bash
#SBATCH --ntasks-per-node=10
#SBATCH --nodes=100
#SBATCH --job-name=IO-500
#SBATCH --time=04:50:00
#SBATCH -o io_500_out_%J
#SBATCH -e io_500_err_%J
#SBATCH --dependency=singleton

ROOT=/home/dkrz/k202079/work/io-500/io-500-dev
module load intel mxm/3.4.3082 fca/2.5.2431 bullxmpi_mlx/bullxmpi_mlx-1.2.9.2 cmake/3.2.3 gcc/7.1.0
module load python/3.5.2
workdir=/mnt/lustre02/work/k20200/k202079/io500/data

source $ROOT/venv/bin/activate

# turn these to True successively while you debug and tune this benchmark.
# for each one that you turn to true, go and edit the appropriate function.
# to find the function name, see the 'main' function.
# These are listed in the order that they run.
io500_run_ior_easy="True" # does the write phase and enables the subsequent read
io500_run_md_easy="True"  # does the creat phase and enables the subsequent stat
io500_run_ior_hard="True" # does the write phase and enables the subsequent read
io500_run_md_hard="True"  # does the creat phase and enables the subsequent read
io500_run_find="True"
io500_run_ior_easy_read="True"
io500_run_md_easy_stat="True"
io500_run_ior_hard_read="True"
io500_run_md_hard_stat="True"
io500_run_md_easy_delete="True" # turn this off if you want to just run find by itself
io500_run_md_hard_delete="True" # turn this off if you want to just run find by itself
io500_run_mdreal="False"  # this one is optional
io500_cleanup_workdir="False"  # this flag is currently ignored. You'll need to clean up your data files manually if you want to.

function setup_directories {
  # set directories for where the benchmark files are created and where the results will go.
  # If you want to set up stripe tuning on your output directories or anything similar, then this is good place to do it.
  timestamp=`date +%Y.%m.%d-%H.%M.%S`           # create a uniquifier
  io500_workdir=$workdir # directory where the data will be stored
  io500_result_dir=/mnt/lustre02/work/k20200/k202079/io500/results-100-new      # the directory where the output results will be kept
  mkdir -p $io500_workdir $io500_result_dir

  # precreate directories for lustre with the appropriate striping
  mkdir -p ${io500_workdir}/ior_easy
  lfs setstripe --stripe-count 2  ${io500_workdir}/ior_easy

  mkdir -p ${io500_workdir}/ior_hard
  lfs setstripe --stripe-count 100  ${io500_workdir}/ior_hard
}

function setup_paths {
  # Set the paths to the binaries.  If you ran ./utilities/prepare.sh successfully, then binaries are in ./bin/
  io500_ior_cmd=$ROOT/bin/ior
  io500_mdtest_cmd=$ROOT/bin/mdtest
  io500_mdreal_cmd=$ROOT/bin/md-real-io
  io500_mpirun="srun -m block"
  io500_mpiargs=""
}

function setup_ior_easy {
  io500_ior_easy_params="-t 2048k -b 122880000k -F" # 2M writes, 2 GB per proc, file per proc
}

function setup_mdt_easy {
  io500_mdtest_easy_params="-u -L" # unique dir per thread, files only at leaves
  io500_mdtest_easy_files_per_proc=6000
}

function setup_ior_hard {
  io500_ior_hard_writes_per_proc=11000
}

function setup_mdt_hard {
  io500_mdtest_hard_files_per_proc=6000
}

function setup_find {
  #
  # setup the find command. This is an area where innovation is allowed.
  #    There are two default options provided. One is a serial find and the other
  #    is a parallel version.
  #    If a custom approach is used, please provide enough info so others can reproduce.

  # the serial version that should run (SLOWLY) without modification
  #io500_find_mpi="False"
  #io500_find_cmd=$ROOT/bin/sfind.sh
  # a parallel version that might require some work, it is a python3 program
  # if you used utilities/prepare.sh, it should already be there.
  io500_find_mpi="True"
  io500_find_cmd=$ROOT/bin/pfind
}

function setup_mdreal {
  io500_mdreal_params="-P=5000 -I=1000"
}

function run_benchmarks {
  # Important: source the io500_core.sh script.  Do not change it. If you discover
  # a need to change it, please email the mailing list to discuss
  cd $ROOT
  source ./bin/io500_fixed.sh 2>&1 | tee $io500_result_dir/io-500-summary.txt
}

# Add key/value pairs defining your system if you want
# This function needs to exist although it doesn't have to output anything if you don't want
function extra_description {
  echo "System_name='DKRZ Mistral Phase2'"
}

rm -rf $workdir

setup_directories
setup_paths
setup_ior_easy # required if you want a complete score
setup_ior_hard # required if you want a complete score
setup_mdt_easy # required if you want a complete score
setup_mdt_hard # required if you want a complete score
setup_find     # required if you want a complete score
setup_mdreal   # optional
run_benchmarks
