# This repository contains scripts for running the IO-500

## How to prepare an IO-500 run

1) Find is part of the benchmark, we prepared several find commands.
   To identify a suitable find (see the find directory / structure of the repository below).
2) You have to prepare a run script for your batch system
   2.1) Set filenames for the benchmarks and find.
   2.2) Add suitable parameters to yield a 5 minute limit for all creation/write benchmark phases.
          You can set parameters for 
          The sample scripts in the directories provide examples for parameters you may want to use.
   2.3) You may add further commands to precreate directories (e.g., to place them on Lustre servers)
   2.4) You may output some key-value pairs for node information (e.g., date, ppn, number of nodes used), these key-values are not yet standardized, but will in the future.
   2.5) Source io_500_core.sh at last to have the script run the benchmarks, do not change io_500_core.sh !   
3) Have it run and store the output in a textfile.

Please see samples in site-configs/*/startup.sh, as those contain all necessary parameters and have been run successfully!
They also contain some documentation.

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
