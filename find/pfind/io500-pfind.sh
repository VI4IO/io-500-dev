#!/bin/bash
# feel free to replace this command with another command
# Input arguments is the workdir
# Expected output is the number of found entities divided by the runtime, e.g., ioops for the found entities
# When using the io500-find.sh script use typically 2x the number of logical machine cores to get best performance
timestamp=$1
workdir="$2"

find ${workdir}/ -name \*.mdtest.\* -newer $timestamp  -size 0c | wc -l > $3

