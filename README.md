## IO 500 in Four Easy Steps

*NOTE: please use the "IO500/io500" repo for SC20 and later list submissions*

```bash
git clone https://github.com/IO500/io500.git
cd io500
./prepare.sh
./io500.sh
```

This is designed to work from an interactive login (e.g. it won't work from a login node) and uses 'mpirun -np 2' to do the simplest possible MPI run. The default declared workload can be used for the required stonewall of 300 seconds, you can just change the stonewall value for testing purposes but for the official ssubmission should be set equal to 300 seconds. You may also need to take whatever steps necessary to run it with a job scheduler. Hopefully it just works for you; if it doesn't, please let us know.

[Our documents directory](https://github.com/VI4IO/io-500-dev/tree/master/doc) has more detailed instructions including how to submit once you have successfully run.

Thanks for your participation and good luck!  

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1422814.svg)](https://doi.org/10.5281/zenodo.1422814)

To Cite:
Julian Kunkel, George Markomanolis, John Bent, & Jay Lofstead. (2018, September 20). VI4IO/io-500-dev: Zenodo Citation Release (Version v1.1). Zenodo. http://doi.org/10.5281/zenodo.1422814

[BibTeX](doc/io500.bib)
