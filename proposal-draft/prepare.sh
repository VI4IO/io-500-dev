#!/bin/bash

echo "This script downloads the code for the benchmarks."

mkdir download 2>/dev/null

cd download
git clone https://github.com/LLNL/mdtest.git
git clone https://github.com/LLNL/ior.git
git clone https://github.com/JulianKunkel/md-real-io

