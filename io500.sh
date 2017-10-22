#!/bin/bash
#
# INSTRUCTIONS:
# Edit this file as needed for your machine.
# This simplified version is just for running on a single node.
# It is a simplified version of the site-configs/sandia/startup.sh which include SLURM directives.
# Most of the variables set in here are needed for io500_core.sh which gets sourced at the end of this.

set -euo pipefail  # better error handling

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
io500_run_md_easy_delete="True"
io500_run_md_hard_delete="True"
io500_run_mdreal="False"  # this one is optional
io500_cleanup_workdir="True"

function main {
  setup_directories
  setup_paths    
  setup_ior_easy # required if you want a complete score
  setup_ior_hard # required if you want a complete score
  setup_mdt_easy # required if you want a complete score
  setup_mdt_hard # required if you want a complete score
  setup_find     # required if you want a complete score
  setup_mdreal   # optional
  run_benchmarks
}

function setup_directories {
  # set directories for where the benchmark files are created and where the results will go.
  # If you want to set up stripe tuning on your output directories or anything similar, then this is good place to do it. 
  timestamp=`date +%Y.%m.%d-%H.%M.%S`           # create a uniquifier
  io500_workdir=$PWD/datafiles/io500.$timestamp # directory where the data will be stored
  io500_result_dir=$PWD/results/$timestamp      # the directory where the output results will be kept
  mkdir -p $io500_workdir $io500_result_dir
}

function setup_paths {
  # Set the paths to the binaries.  If you ran ./utilities/prepare.sh successfully, then binaries are in ./bin/
  io500_ior_cmd=$PWD/bin/ior
  io500_mdtest_cmd=$PWD/bin/mdtest
  io500_mdreal_cmd=$PWD/bin/md-real-io
  io500_mpirun="mpirun"
  io500_mpiargs="-np 2"
}

function setup_ior_easy {
  io500_ior_easy_params="-t 2048k -b 2g -F" # 2M writes, 2 GB per proc, file per proc 
}

function setup_mdt_easy {
  io500_mdtest_easy_params="-u -L" # unique dir per thread, files only at leaves
  io500_mdtest_easy_files_per_proc=6100
}

function setup_ior_hard {
  io500_ior_hard_writes_per_proc=60
}

function setup_mdt_hard {
  io500_mdtest_hard_files_per_proc=6100
}

function setup_find {
  #
  # setup the find command. This is an area where innovation is allowed.
  #    There are two default options provided. One is a serial find and the other
  #    is a parallel version. 
  #    If a custom approach is used, please provide enough info so others can reproduce.

  # the serial version that should run (SLOWLY) without modification
  io500_find_cmd=$PWD/utilities/find/sfind.sh

  # a parallel version that might require some work, it requires python3 and needs
  # to be checked out from a different repo.  See utilities/find/README.md for more info.
  #io500_find_cmd=$PWD/utilities/find/pfind.sh
}

function setup_mdreal {
  io500_mdreal_params="-P=5000 -I=1000"
}

function run_benchmarks {
  # Important: source the io500_core.sh script.  Do not change it. If you discover
  # a need to change it, please email the mailing list to discuss
  source io500_fixed.sh 2>&1 | tee $io500_result_dir/io-500-summary.$timestamp.txt
}

# Add key/value pairs defining your system if you want
# This function needs to exist although it doesn't have to output anything if you don't want
function extra_description {
  echo "System_name='JohnBentLaptop'"
}

main
