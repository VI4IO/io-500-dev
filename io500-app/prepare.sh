#!/bin/bash

git clone https://github.com/JulianKunkel/ior-1.git

# Setup config.h for IOR
pushd ./ior-1
./bootstrap
./configure
popd

echo Now adapt or run ./compile.sh
