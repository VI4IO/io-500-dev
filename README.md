# This repository contains scripts for running the IO-500

## Building the necessary benchmarks

Download the source code of the benchmarks:
* mdtest
* ior
* md-real-io (optional)

The script ./prepare.sh gives an example how to download and build these benchmarks.

## How to prepare an IO-500 run

Please see the template in site-configs/template/startup.sh or samples in site-configs/*/startup.sh, as those contain all necessary parameters and have been run successfully!
They also contain some documentation.
If you have installed the benchmarks into $PWD/install/, e.g., using the ./prepare.sh script, 
you may use the script startup-io500-locally-testmode.sh that runs all benchmarks for testing in a quick run
in the current directory.

The general procedure to run successfully are:

1) Identify a suitable find command; find is part of the benchmark, we prepared several find commands.
   To identify a suitable find (see the find directory / structure of the repository below).
2) You have to prepare a run script for your batch system
   2.1) Set filenames for the benchmarks and find.
   2.2) Add suitable parameters to yield a 5 minute limit for all creation/write benchmark phases.
          You can set parameters for ior_easy, example:
           ior_easy_params="-t 2048k -b 122880000k" # 120 GBytes per process, file per proc is already configured
           ior_hard_writes_per_proc=5000   #each process writes 5000 times
           mdtest_hard_files_per_proc=6000
           mdtest_easy_files_per_proc=6000

          Sample scripts in the directories provide examples for parameters you may want to use.
   2.3) You may add further commands to precreate directories (e.g., to place them on Lustre servers)
   2.4) You may output some key-value pairs for node information (e.g., date, ppn, number of nodes used), these key-values are not yet standardized, but will in the future.
   2.5) Source io_500_core.sh at last to have the script run the benchmarks, do not change io_500_core.sh !
3) Have it run and store the output in a textfile.
4) Submit the script to your batch system.

To see what the benchmark will do set find_cmd, ior_cmd, mdtest_cmd to /bin/echo or have your jobscript use "/usr/bin/bash -x"

## How to identify suitable settings

Alternatives:
* Manually identification, e.g., you know the parameters or tested them.
* You may use the auto-determine-parameters.sh script which uses an explorative search to identify (nearly) suitable settings.
  This script can be used similarly to io_500_core.sh, except that you do not have to set the parameters for the phases.

See again samples in site-configs/*/startup-auto-detect.sh

## Structure of the repository

### Directories

* find: contains all alternatives for find, currently:
   * a bash paralellized version (single node)
   * an MPI paralellized find version (see the directory pfind)
* site-configs: contains the run scripts (!) for certain sites together with results.
  They provide good examples to start with.
* prepare.sh: This script downloads and attempts to build the codes. 
  Building may fail on certain systems, please prepare a script for your system to build correctly.
* startup-io500-locally-testmode.sh: This script runs the IO500 benchmark on the current working directory.
  It serves as a basis to test if everything runs correctly on your system.
  It requires that you installed the executables into the install/ directory
