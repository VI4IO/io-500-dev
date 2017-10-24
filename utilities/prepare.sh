#!/bin/bash -e

set -e

echo This script downloads the code for the benchmarks
echo It will also attempt to build the benchmarks
echo It will output OK at the end if builds succeed

IOR_HASH=e1968cd4ad50d3d5dee853ae3b1a8724f4f072c7
MDREAL_HASH=f1f4269666bc58056a122a742dc5ca13be5a79f5 

INSTALL_DIR=$PWD
BUILD=$PWD/build
MAKE="make -j4"

function main {
  setup
  get_build_ior
  get_pfind
  ls $INSTALL_DIR/bin
}

function setup {
  rm -rf $BUILD
  mkdir -p $BUILD $INSTALL_DIR/bin 
}

function git_co {
  cd $BUILD
  git clone $1
  cd $2
  git checkout $3
}

function get_pfind {
  cd $INSTALL_DIR/utilities/find
  \rm -rf pwalk
  git clone https://github.com/johnbent/pwalk.git
}

function get_build_ior {
  git_co https://github.com/IOR-LANL/ior ior $IOR_HASH
  ./bootstrap
  ./configure --prefix=$INSTALL_DIR
  cd src # just build the source
  $MAKE install
}

function get_build_mdrealio {
  git_co https://github.com/JulianKunkel/md-real-io md-real-io $MDREAL_HASH
  ./configure --prefix=$PWD --minimal
  cd build
  $MAKE install
  mv src/md-real-io $INSTALL_DIR/bin
}

main
