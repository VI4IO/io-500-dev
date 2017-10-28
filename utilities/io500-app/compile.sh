#!/bin/bash -e
CC=mpicc
CFLAGS="-g -O2 -DMDTEST_LIBRARY -fstack-protector-all -Wextra"

pushd ior-1
echo "Building IOR + MDTEST"

$CC $CFLAGS -c -o ior-opt.o getopt/optlist.c
$CC $CFLAGS -I. -DLinux -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE=1 -D__USE_LARGEFILE64=1 -Dmain=main_mdtest -c src/mdtest.c

$CC -DHAVE_CONFIG_H -I. $CFLAGS -Dmain=main_ior -c -o ior-ior.o src/ior.c
$CC -DHAVE_CONFIG_H -I. $CFLAGS -c -o ior-utilities.o src/utilities.c
$CC -DHAVE_CONFIG_H -I. $CFLAGS -c -o ior-aiori.o src/aiori.c
$CC -DHAVE_CONFIG_H -I. $CFLAGS -c -o ior-parse_options.o src/parse_options.c
$CC -DHAVE_CONFIG_H -I. $CFLAGS -c -o ior-aiori-MPIIO.o src/aiori-MPIIO.c
$CC -DHAVE_CONFIG_H -I. $CFLAGS -c -o ior-aiori-POSIX.o src/aiori-POSIX.c
popd

echo "Building IO500"
$CC $CFLAGS -Wall -I ior-1/src -c src/io500-core.c || exit 1
$CC $CFLAGS -Wall -I ior-1/src -I libcircle/libcircle/ -c src/io500-find.c || exit 1
$CC $CFLAGS -o io500 ior-1/*.o *.o libcircle/.libs/libcircle.a -lm  || exit 1

echo "[OK]"
