#!/bin/bash 
echo -e "#!/bin/bash\n" > $2

if [ $1 -eq 1 ]; then
echo -e "#SBATCH --ntasks-per-node=
#SBATCH --nodes=
#SBATCH --job-name=IO-500
#SBATCH --time=
#SBATCH -o io_500_out_%J
#SBATCH -e io_500_err_%J\n" >> $2

elif [ $1 -eq 2 ]; then
echo -e "#PBS -l select=:mpiprocs=
#PBS -N IO-500
#PBS -l walltime=
#PBS -o io_500_out
#PBS -e io_500_err" >> $2
fi
