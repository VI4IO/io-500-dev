# This repository contains scripts for running the IO-500

## How to prepare an IO-500 run

1) Identify a suitable find (see find directory)
2) Prepare a run script for your batch system (see samples in site-configs/*/startup.sh)
   Set command directories (see example run scripts)
   Have it source io_500_core.sh
3) Identify suitable parameters to yield the 5 minute limit (see below)
4) Have it run

## How to identify suitable settings

Options:
* Manually identification
* Usage of the auto-determine-parameters.sh script
  This script can be used similarly to io_500_core.sh, except that you do not have to set
  default parameters. See samples in site-configs/*/startup-auto-detect.sh

## Structure of the repository

### Directories

* find: contains all alternatives for find, currently:
   * a bash paralellized version (single node)
   * an MPI paralellized find version (see the directory pfind)
* site-configs: contains the run scripts (!) for certain sites together with results.
  They provide good examples to start with.
