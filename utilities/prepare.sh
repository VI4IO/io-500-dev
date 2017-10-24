#!/bin/bash -e

set -e

echo This script downloads the code for the benchmarks
echo It will also attempt to build the benchmarks
echo It will output OK at the end if builds succeed
echo

IOR_HASH=e1968cd4ad50d3d5dee853ae3b1a8724f4f072c7
MDREAL_HASH=f1f4269666bc58056a122a742dc5ca13be5a79f5

INSTALL_DIR=$PWD
BIN=$INSTALL_DIR/bin
BUILD=$PWD/build
MAKE="make -j4"

function main {
  setup
  get_build_ior
  get_pfind
  ls $BIN
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
  echo "Preparing parallel find"
  pushd $BUILD
  rm -rf pwalk
  git clone https://github.com/johnbent/pwalk.git
  cp -r pwalk/pfind pwalk/lib $BIN
  cp $INSTALL_DIR/utilities/find/pfind.sh $INSTALL_DIR/utilities/find/sfind.sh $BIN
  echo "Pfind: OK"
  echo
  popd
}

function get_build_ior {
  echo "Preparing IOR"
  git_co https://github.com/IOR-LANL/ior ior $IOR_HASH
  ./bootstrap
  ./configure --prefix=$INSTALL_DIR
  pushd src # just build the source
  $MAKE install
  echo "IOR: OK"
  echo
  popd
}

function get_build_mdrealio {
  echo "Preparing MD-REAL-IO"
  git_co https://github.com/JulianKunkel/md-real-io md-real-io $MDREAL_HASH
  ./configure --prefix=$PWD --minimal
  pushd build
  $MAKE install
  mv src/md-real-io $INSTALL_DIR/bin
  echo "MD-REAL-IO: OK"
  echo
  popd
}

main
