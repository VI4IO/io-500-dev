# Instructions


## Lustre:

It is required to execute some benchmarks for 5 minutes. Thus, an auto-tuning tool was developed to calculate the appropriate parameters depending on your system.

### Auto-tuning:

1) Edit the file startup-auto-detect.sh

* Change resource allocation and paths. If you plan to use another job scheduler adjust the commands.
* Provide enough time limit to your job
* If you want to execute mdreal, define the parameter mdreal_cmd 
 
2) Submit the auto-tuning tool.

### Main script

3) Edit the file startup.sh


* Add the parameters that the auto-tuning tool provided. For example:

```bash
ior_easy_params="-t 2m -b 5440m"
ior_hard_writes_per_proc=792
mdtest_easy_files_per_proc=380
mdtest_hard_files_per_proc=452
```
4) In the case that you want to use parallel find

* Modify the parameter processes_find to the number of the MPI processes that should participate in the parallel find
* Define the following (uncomment or comment where necessary)

```bash
find_cmd=$PWD/../io500-pfind.sh

run_pfind="True"
run_find="False"
```
* Modify the compile.sh file from the main folder (prposal-draft) and execute it to compile the pfind executable

5) Submit the main script.

## Cray Burst Buffer:

As previously but the auto-tuning tool is called startup-auto-detect-datawarp-bb.sh and the main script startup-datawarp-bb.sh



# Submission of results

The output files are located in the output_dir directory

To be updated

