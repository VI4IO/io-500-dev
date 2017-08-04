#!/bin/bash

cc=cc

$cc -o pfind mpi_find.c

cp pfind ../
echo "Copy the executable pfind in the proposal-draft folder"
