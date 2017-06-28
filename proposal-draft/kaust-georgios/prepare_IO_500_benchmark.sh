#!/bin/bash 

source parameters.txt

if [ $scheduler -eq 1 ]; then

#echo "SLURM scheduler"

cat scheduler_slurm.sh > io500.sh
sed -i.bak "s/ntasks=/ntasks=$procs/g"  io500.sh 
sed -i.bak "s/ntasks-per-node=/ntasks-per-node=$procs_per_node/g"  io500.sh

if [ $job_duration -lt 60 ]; then

real_time="00:00:"$job_duration

else

hours=$(($job_duration/60))
minutes=$(($job_duration%60))

real_time="00:"$(printf %02d $hours)":"$(printf %02d $minutes)

fi
sed -i.bak "s/time=/time=${real_time}/g"  io500.sh
if [ "$mpirun"=="srun" ]; then

	mpirun="srun -n ${procs} --ntasks-per-node=${procs_per_node} "$extra
fi

fi

cat parameters.txt | grep -v mpirun >> io500.sh

echo -e "\nUsed mpirun alias\n" >> io500.sh
echo "mpirun="srun -n ${procs} --ntasks-per-node=${procs_per_node} "$extra" >> io500.sh

cat io_500_core.sh >> io500.sh
