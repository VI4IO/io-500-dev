## Cleaning up after a run

The rm command is slower than unlink. Prefer unlink for a faster operation. Lustre offers an munlink tool that does just this. The program is [here](https://github.com/hpc/lustre/blob/master/lustre/tests/munlink.c).

## Getting Parallel Find to run

You will need to have Python 3.6 installed to get access to the more efficient system call and need [Mpi4Py](https://bitbucket.org/mpi4py/mpi4py) installed and in the PYTHONPATH to run the program.

## Debugging before scaling up

We have run into some issues that only appear when 2 or more nodes are used. If you can test with at least 2 nodes you should find fewer problems when scaling up.

## Parameter Exploration for "Best" Settings

Consdier the following factors:
1. Storage targets in the system. Consider that you have 160 Lustre storage targets.
2. network bandwidth both out of the compute nodes and into the storage target nodes. If each storage target can take 150 MB/sec sustained, then figure out the network bandwidth from each node aggregate and per process to estimate the spread to get the best saturation chance.

Don't bother trying to optimize for caching. The benchmarks are configured to overwhelm any chaching to make it a true test of the storage system rather than the network.
