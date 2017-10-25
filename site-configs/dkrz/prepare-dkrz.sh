#!/bin/bash

module load intel mxm/3.4.3082 fca/2.5.2431 bullxmpi_mlx/bullxmpi_mlx-1.2.9.2 cmake/3.2.3 gcc/7.1.0
module load automake/1.14.1
module load autoconf

echo "Installing dependencies"

cd ../../
./utilities/prepare.sh

echo "Patching pfind (1/2)"
pushd bin
patch -p0 < ../site-configs/dkrz/pfind.patch
popd

echo "Preparing VirtualEnv for Python"
module load python/3.5.2
virtualenv -p python3 venv
source venv/bin/activate
pip3 install mpi4py # CC=mpicc
