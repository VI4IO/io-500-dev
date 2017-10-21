# This repository contains scripts for running and parsing the IO-500

The goal of this benchmark is to both offer a competitive contest for the best overall storage system as well as to collect best practices for achieving that performance. With those best practices, people can try those techniques on their own systems to try to improve their IO behavior.

The standard is to do both easy and hard tests using IOR. Hard is preconfigured. Easy is up to the benchmark runner. For metadata operations, each of create, stat, and delete are tested using both an easy and a hard setup.

The last test is a find across a large set of files. The provided utility in this archive can hopefully offer a much improved performance approach to this operation compared with a serial tool. Substituting your own tool is acceptable--as long as it is released as part of your benchmark results.

Each of the tests is required to run for a minimum of 5 minutes to ensure that any caches are flushed and to represent the allowed time for large scale runs for checkpoint operations on a per hour basis. A warning is generated if a test fails to meet this standard. Since the easy tests are user configured, we require that all configuration information be provided along with the results so that others can hopefully duplicate the technique and also improve their IO performance. Overall, we encourage gaming the easy tests as long as full instructions for how that was done is provided as part of the benchmark submission.

A final, but optional, part of the benchmark is the proposed md-real-io that seeks to offer a more accurate test than mdtest. If users running this benchmark could also run md-real-io to offer a comparison, it will help with validating the approach. Publication credit is available for those that participate. Please mention this in your submission if you wish to participate.

## Build the necessary benchmarks

Download and build the source code of these benchmarks into a subdirectory named 'bin'. Specific repo version hash codes are provided in the prepare.sh script. If you wish to do this manually, please ensure that the same repo versions are used for consistency. If your file system requires custom code not offered in the selected repo versions, please contact us. We want to expand the coverage, but work to ensure that results are comparable.

* REQUIRED: mdtest https://github.com/LLNL/mdtest.git 
* REQUIRED: ior https://github.com/IOR-LANL/ior.git 
* OPTIONAL: md-real-io https://github.com/JulianKunkel/md-real-io 

The script ./utilities/prepare.sh attempts to download and build these. 
If you do it yourself, please checkout the exact version of each benchmark using the hashes in the utilities/prepare.sh file.

## Prepare your IO-500 run

Please see the template in site-configs/template/startup.sh or samples in site-configs/*/startup.sh, as those contain all necessary parameters and have been run successfully!
They also contain some documentation.
If you have installed the benchmarks into $PWD/install/, e.g., using the ./prepare.sh script, 
you may use the script startup-io500-locally-testmode.sh that runs all benchmarks for testing in a quick run
in the current directory.

The general procedure to run successfully are:

1. Identify a suitable find command; find is part of the benchmark, we prepared several find commands.
   To identify a suitable find (see the find directory / structure of the repository below).
1. Set filenames for the benchmarks and find.
2. Add suitable parameters to yield a 5 minute limit for all creation/write benchmark phases.
   You can set parameters for ior_easy, example:
   
   ior_easy_params="-t 2048k -b 122880000k" # 120 GBytes per process, file per proc is already configured
   
   ior_hard_writes_per_proc=5000   #each process writes 5000 times
   
   mdtest_hard_files_per_proc=6000
   
   mdtest_easy_files_per_proc=6000

   Sample scripts in the directories provide examples for parameters you may want to use.
   
3. You may add further commands to precreate directories (e.g., to place them on Lustre servers)
4. You may output some key-value pairs for node information (e.g., date, ppn, number of nodes used), these key-values are not yet standardized, but will in the future.
5. Source io_500_core.sh at last to have the script run the benchmarks, do not change io_500_core.sh !
6. Have it run and store the output in a textfile.
7. Submit the script to your batch system.

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
  
## Submitting your results
To submit results, prepare a directory under site-config, appropriately name, containing the following items:
1. The results directory
2. The overall output file
3. Scripts used to run the tests
4. Source code for custom tools used for the easy tests or find operation
5. if a different version of any repo is used to source the code than the ones listed in prepare.sh, include those repo hash keys.
  
Make a separate submission directory for each file system (or storage layer) tested. Please use a site-fs naming convention as a pattern. Other parts are probably required. Use good judgement.
  
Generate a pull request to vi4io/io-500-dev to start the process.
  
Thank you for participating and good luck!
  
