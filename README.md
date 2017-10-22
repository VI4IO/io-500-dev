## How to run the IO500

## Build the necessary benchmarks

Download and build the source code of these benchmarks into a subdirectory named 'install'.

*  REQUIRED: mdtest https://github.com/LLNL/mdtest.git 
*  REQUIRED: ior https://github.com/IOR-LANL/ior.git 
*  OPTIONAL: md-real-io https://github.com/JulianKunkel/md-real-io 

The script ./utilities/prepare.sh attempts to download and build these. 
If you do it yourself, please checkout the exact version of each benchmark using the hashes in the utilities/prepare.sh file.

## Prepare and run your IO-500 submision

Edit io500.sh.  We have attempted to make it self-explanatory.  Note that it is intended to run from a command prompt.  If you want to run it with a job scheduler, we assume you know how to do that.  It is also intended to just run very small test amounts.  You will need to increase the amount of data being written and files being created until you satisfy the rules.

There are in site-configs/*/startup.sh that show how others have done this.

You will also probably want to make extensive edits to ./io500_find.sh as it is currently a single threaded serial find command that will take a very long time to run if you create any reasonably large quantities of files.

## Tuning suggestions

It is recommended that you tune your system for maximum performance.  For example, setting different striping parameters for your IOR hard and easy directories and mdtest easy and hard as well.  If you do so, you are encouraged to include your configuration with your submission to help the entire community.

## IO500 Individual benchmarks

The complete test includes the following benchmarks:

1. **IOR easy**. You can set the parameters to be whatever you would like.  You can use any of the modules such as HDF5 or MPI-IO.  Typically people maximize performance by doing file-per-process and large aligned IO.
2. **IOR hard**.  We enforce a particular set of parameters.  Specifically, the IOs are 47008 bytes each interspersed in a single shared file.  Your only control is to specify how many writes each thread does.
3. **mdtest easy**.
 You can set the parameters to be whatever you would like.  Any module and any other parameters.  Typically performance is maximized with using a unique directory by process and doing empty files. 
4. **mdtest hard**.  We enforce a particular set of parameters.  Specifically, all the processes create files in a single shared directory and they write 3900 bytes to them.  Your only control is to specify how many files each process creates.
5. **find**. This benchmark allows the most flexibility.  See the default ./io500_find.sh to understand the required input arguments and output format.  Then you can edit it in whatever way maximizes performance for your particular system.
6. **md-real-io**. This benchmark is optional.

## IO500 Rules and submission instructions

The rules are simple.  You can submit whatever you want and we will include it in the community repository of results.  But if you would like an official score and a place on the official scored list, you must run all of the required benchmarks and your write/create phases must run for at least five minutes.

To submit your results, email your tarballed results directory to <submit@io500.org>.

## IO500 Help
For help, we offer multiple communications channels: <https://www.vi4io.org/std/io500/start#communication_contribution>.

## IO500 Motivation
We thank you for your interest in the IO500.  We appreciate that there is some effort involved and we thank you in advance for it.  We believe that this effort is worthwhile for the following reasons:

1. To create an historical repository of HPC IO performance over time.
2. To encourage the community and storage system developers to focus on more than just the *hero* runs.
3. To create bounded sets of IO performance for users.
4. To create a documentation repository of how others are tuning their systems and their IO workloads.
5. To foster a research community dedicated to the improvement of HPC storage systems.