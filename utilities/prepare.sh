#!/bin/bash -e

set -e

echo This script downloads the code for the benchmarks
echo It will also attempt to build the benchmarks
echo It will output OK at the end if builds succeed

MDTEST_HASH=7c0ec411c762d65db137997526b9feca9d2d0046 
IOR_HASH=2541bfea7bd6c8d85f928e7f64f55e7ae02b5e3a 
MDREAL_HASH=f1f4269666bc58056a122a742dc5ca13be5a79f5 

# Install and build dirs
BIN=$PWD/bin
BUILD=$PWD/build

MAKE="make -j4"

rm -rf $BUILD
mkdir -p $BUILD $BIN 2>/dev/null || true

cd $BUILD
git clone https://github.com/MDTEST-LANL/mdtest || true
git clone https://github.com/IOR-LANL/ior || true
git clone https://github.com/JulianKunkel/md-real-io || true

echo "Compiling benchmarks"

cd $BUILD/mdtest
git checkout $MDTEST_HASH
$MAKE CC.Linux="mpicc -Wall"
mv mdtest $BIN

cd $BUILD/ior
git checkout $IOR_HASH
./bootstrap
./configure --prefix=$PWD
cd src # just build the source
$MAKE install
cd $BUILD

cd md-real-io
git checkout $MDREAL_HASH
#./configure --prefix=$PWD --minimal
#$MAKE install

ls $BIN
