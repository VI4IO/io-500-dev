#!/bin/bash 

source parameters.txt

if [ $scheduler -eq 1 ]; then

#echo "SLURM scheduler"

cat scheduler_slurm.sh > io500.sh
sed -i.bak "s/nodes=/nodes=$nodes/g"  io500.sh 
sed -i.bak "s/ntasks-per-node=/ntasks-per-node=$procs_per_node/g"  io500.sh

if [ $job_duration -lt 60 ]; then

real_time="00:00:"$job_duration

else

hours=$(($job_duration/60))
minutes=$(($job_duration%60))

real_time="00:"$(printf %02d $hours)":"$(printf %02d $minutes)

fi
sed -i.bak "s/time=/time=${real_time}/g"  io500.sh

if [ $filesystem -eq 3 ]; then

 echo "#DW jobdw type=scratch access_mode=striped capacity=800GiB" >> io500.sh
fi
cat parameters.txt | grep -v mpirun >> io500.sh
mpi_procs=$(($nodes*$procs_per_node))
if [ "$mpirun"=="srun" ]; then

	mpirun="srun -n $mpi_procs --ntasks-per-node=${procs_per_node} "$extra

echo -e "\n#Used mpirun alias\n" >> io500.sh
echo "mpirun=\"srun -n $mpi_procs --ntasks-per-node=${procs_per_node} "$extra\" >> io500.sh


elif [ "$mpirun"=="mpirun" ]; then

        mpirun="mpirun -np $mpi_procs --npernode ${procs_per_node} "$extra
echo -e "\nUsed mpirun alias\n" >> io500.sh
echo "mpirun=\"mpirun -np $mpi_procs --npernode ${procs_per_node} "$extra\" >> io500.sh
fi

fi



cat io_500_core.sh >> io500.sh
