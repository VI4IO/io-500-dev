#!/bin/bash
#SBATCH --ntasks-per-node=5
#SBATCH -p compute2
#SBATCH -A k20200
#SBATCH --nodes=200
#SBATCH --job-name=IO-500
#SBATCH --time=04:50:00
#SBATCH -o io_500_out_%J
#SBATCH -e io_500_err_%J
#SBATCH --dependency=singleton

./startup.sh
