
## Build the necessary benchmarks

Download and build the source code of these benchmarks.  Specific repo version hash codes are provided in the prepare.sh script. If you wish to do this manually, please ensure that the same repo versions are used for consistency. If your file system requires custom code not offered in the selected repo versions, please contact us. We want to expand the coverage, while also working to ensure that results are comparable.

* REQUIRED: mdtest https://github.com/LLNL/mdtest.git 
* REQUIRED: ior https://github.com/IOR-LANL/ior.git 
* USEFUL: pfind https://github.com/johnbent/pwalk.git
* OPTIONAL: md-real-io https://github.com/JulianKunkel/md-real-io 

The script ./utilities/prepare.sh attempts to download and build these. 
If you do it yourself, please checkout the exact version of each benchmark using the hashes in the utilities/prepare.sh file.

## Prepare and run your IO-500 submision

Edit io500.sh.  We have attempted to make it self-explanatory.  Note that it is intended to run from a command prompt.  If you want to run it with a job scheduler, we assume you know how to do that.  It is also intended to just run very small test amounts.  You will need to increase the amount of data being written and files being created until you satisfy the rules.  Once you are done with your edits, merely run it.  The way it works is that it then calls io500_fixed.sh which actually runs all of the benchmarks using the parameters and configuration that you set in io500.sh.  The intent is that io500_fixed.sh should *not* be edited.  If you discover a need to edit it, please contact us on our communication channels, <https://www.vi4io.org/std/io500/start#communication_contribution>, to discuss.

There may be examples in site-configs/\*/startup.sh that show how others have edited the io500.sh to tune, to size, and to get it working with a job scheduler.

You will also probably want to replace the default use of ./io500_find.sh as it is currently a single threaded serial find command that will take a very long time to run if you create any reasonably large quantities of files.  There is a parallel version also available.  Read 'setup_find' in io500.sh to see how to turn it on and then read 'utilities/find/README.md' to see how to install it.

## Tuning suggestions

It is recommended that you tune your system for maximum performance.  For example, setting different striping parameters for your IOR hard and easy directories and mdtest easy and hard as well.  If you do so, you are encouraged to include your configuration with your submission to help the entire community.

## IO500 Individual benchmarks

The complete test includes the following benchmarks:

1. **IOR easy**. You can set the parameters to be whatever you would like.  You can use any of the modules such as HDF5 or MPI-IO.  Typically people maximize performance by doing file-per-process and large aligned IO.
2. **IOR hard**.  We enforce a particular set of parameters.  Specifically, the IOs are 47008 bytes each interspersed in a single shared file.  Your only control is to specify how many writes each thread does.
3. **mdtest easy**.
 You can set the parameters to be whatever you would like.  Any module and any other parameters.  Typically performance is maximized with using a unique directory by process and doing empty files. 
4. **mdtest hard**.  We enforce a particular set of parameters.  Specifically, all the processes create files in a single shared directory and they write 3901 bytes to them.  Your only control is to specify how many files each process creates.
5. **find**. This benchmark allows the most flexibility.  See the default ./io500_find.sh to understand the required input arguments and output format.  Then you can edit it in whatever way maximizes performance for your particular system.  There is also a parallel version available that is described in utilities/find/README.md.
6. **md-real-io**. This benchmark is optional; it seeks to offer a more accurate test than mdtest. Anyone running this helps explore whether this is needed. The author plans to publish and will share authorship with those participating. 


## IO500 Rules and submission instructions

The rules are simple.  You can submit whatever you want and we will include it in the community repository of results.  But if you would like an official score and a place on the official scored list, you must run all of the required benchmarks and your write/create phases must run for at least five minutes; this is intended ensure that any caches are flushed and to represent the typical checkpoint time of large systems. A warning is generated if a test fails to meet this standard. 

Since the easy tests are user configured, we request that all configuration information be provided along with the results so that others can hopefully duplicate the technique and also improve their IO performance. 

Overall, we encourage *gaming* the easy tests as long as full instructions for how that was done is provided as part of the benchmark submission.

To submit results, prepare a directory under site-config, appropriately name, containing the following items:
1. The results directory
2. The overall output file
3. Scripts used to run the tests
4. Source code for custom tools used for the easy tests or find operation
5. If a different version of any repo is used than the ones listed in prepare.sh, include those repo hash keys.
  
Make a separate submission directory for each file system (or storage layer) tested. Please use a site-fs naming convention as a pattern. Other parts are probably required. Use good judgement.
  
Generate a pull request to vi4io/io-500-dev to start the process.

## IO500 Help
For users needing help, we offer multiple communications channels: <https://www.vi4io.org/std/io500/start#communication_contribution>.

This is a new benchmark and we also ask you to please help us with any feedback you might have by posting it to our communication channels: <https://www.vi4io.org/std/io500/start#communication_contribution>. 

## IO500 Motivation
We thank you for your interest in the IO500.  We appreciate that there is some effort involved and we thank you in advance for it.  We believe that this effort is worthwhile for the following reasons:

1. To create an historical repository of HPC IO performance over time.
2. To encourage the community and storage system developers to focus on more than just the *hero* runs.
3. To create bounded sets of IO performance for users.
4. To create a documentation repository of how others are tuning their systems and their IO workloads.
5. To foster a research community dedicated to the improvement of HPC storage systems.

The overall goal of this benchmark is to both offer a competitive contest for the best overall storage system as well as to collect best practices for achieving that performance. With those best practices, people can try those techniques on their own systems to try to improve their IO behavior.
  
**Thank you for participating and good luck!**
  
