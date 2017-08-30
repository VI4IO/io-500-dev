#!/bin/bash -x

echo "This script downloads the code for the benchmarks."
echo "It will also attempt to built the benchmarks"
echo "It will output [OK] at the end if builds succeeded"

# Install di
INSTALL=$PWD/install

mkdir download 2>/dev/null || true
mkdir install 2>/dev/null || true

cd download
git clone https://github.com/LLNL/mdtest.git || true
git clone https://github.com/IOR-LANL/ior || true
git clone https://github.com/JulianKunkel/md-real-io || true

echo "Compiling benchmarks"

pushd mdtest
if [ -x "$(command -v mpicc)" ]; then
make CC.Linux="mpicc -Wall"
elif [ -x "$(command -v mpicc)" ]; then

module swap PrgEnv-cray PrgEnv-gnu
module swap PrgEnv-intel PrgEnv-gnu
module load cmake
module load autotools
make CC.Linux="cc -Wall"
fi
mv mdtest $INSTALL
popd

pushd ior
./bootstrap
./configure --prefix=$INSTALL
make -j4 install
mv $INSTALL/bin/ior $INSTALL
popd

pushd md-real-io
./configure --prefix=$INSTALL
cd build
make -j4 install
mv $INSTALL/bin/md-real-io $INSTALL
popd

echo "[OK]"
