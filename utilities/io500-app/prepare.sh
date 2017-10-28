#!/bin/bash

git clone https://github.com/JulianKunkel/ior-1.git

# Setup config.h for IOR
pushd ./ior-1
git pull
./bootstrap
./configure
popd


git clone https://github.com/hpc/libcircle.git

pushd libcircle
./configure
make -j
popd

echo Now adapt or run ./compile.sh
