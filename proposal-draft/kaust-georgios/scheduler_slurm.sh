#!/bin/bash

if [ $1 -eq 1 ]; then
#SBATCH --ntasks-per-node=
#SBATCH --nodes=
#SBATCH --job-name=IO-500
#SBATCH --time=
#SBATCH -o io_500_out_%J
#SBATCH -e io_500_err_%J

elif [ $1 -eq 2 ]; then
#PBS -l select=:mpiprocs=
#PBS -N IO-500
#PBS -l walltime=
#PBS -o io_500_out_%J
#PBS -e io_500_err_%J
fi
