#!/bin/bash 

#IO-500 benchmark
#v0.3

#SBATCH --ntasks-per-node=2 
#SBATCH --nodes=512
#SBATCH --job-name=IO-500 
#SBATCH --time=00:50:00
#SBATCH -o io_500_out_%J
#SBATCH -e io_500_err_%J


##DW jobdw type=scratch access_mode=striped capacity=213006GiB

procs=256
procs_per_node=2



# set here the parameters you want
mpirun="srun -n $procs --ntasks-per-node=${procs_per_node}"
#Select filesystem
# 1 for Lustre
# 2 for Cray DataWarp
filesystem=1

if [ $filesystem -eq 1 ]; then
#workdir for Lustre, adapt to your path
#Do not use same path with the current location of your script!
  workdir="/project/k01/markomg/io_test"
  rm -rf $workdir
  mkdir -p $workdir/ior_hard
  
  lfs setstripe -c -1 $workdir/ior_hard
  cp IOR $workdir/ior_hard
mkdir $workdir/ior_easy $workdir/mdt_easy $workdir/mdt_hard
  cp IOR $workdir/ior_easy
  cp mdtest $workdir/mdt_easy
  cp mdtest $workdir/mdt_hard


  ior_easy_params="-t 1m -b 10g"
  cd $workdir

elif [ $filesystem -eq 2 ]; then
  #workdir for Cray DataWarp
  workdir="${DW_JOB_STRIPED}"
  ior_easy_params="-t 512k -b 3195392k"
fi

mdtest_hard_files_per_proc=100 
ior_hard_writes_per_proc=5000
ior_results_file=${SLURM_SUBMIT_DIR}/ior_${SLURM_JOBID}
mdt_results_file=${SLURM_SUBMIT_DIR}/mdt_${SLURM_JOBID}


############
# dont edit below here
############
tmp_dir=`mktemp -d`

function print_bw  {
   printf "Bandwidth $1 is %10.2f MB/s and duration is %6.2f seconds\n" $2 $3 
}

function print_iops  {
   printf "IOPs $1 is %10.2f\n" $2 
}

# ior easy write
cd $workdir/ior_easy
$mpirun IOR -F -e -g -vv -w -G 27 -k $ior_easy_params -o $workdir/ior_easy/ior_file_easy | tee $tmp_dir/ior_easy
bw1=$(grep "Max W" $tmp_dir/ior_easy | sed 's\(\\g' | sed 's\)\\g' | tail -n 1 | awk '{print $5}')

bw_dur1=$(grep "write " $tmp_dir/ior_easy | tail -n 1 | awk '{print $10}')
print_bw 1 $bw1 $bw_dur1 | tee  $ior_results_file


grep -q "file-per-proc" $tmp_dir/ior_easy
if [ $? -eq 0 ]; then
	let ior_easy_files=$procs
else
	let ior_easy_files=1
fi 
#mdtest easy create
cd $workdir/mdt_easy
mkdir temp
$mpirun mdtest -v -C -d ${workdir}/mdt_easy/tmp -u -n $mdtest_hard_files_per_proc | tee $tmp_dir/mdt_easy
iops1=$(grep "File creation" $tmp_dir/mdt_easy | tail -n 1 | awk '{print $4}')
print_iops 1 $iops1 | tee  $mdt_results_file



ts2=`date +%s`
touch $workdir/$ts2

# ior hard write
cd $workdir/ior_hard
$mpirun IOR -e -g -vv -w -G 27 -k -t 47000 -b 47000 -s $ior_hard_writes_per_proc -o ${workdir}/ior_hard/IOR_file | tee $tmp_dir/ior_hard
bw2=$(grep "Max W" $tmp_dir/ior_hard | sed 's\(\\g' | sed 's\)\\g' | tail -n 1 | awk '{print $5}')

bw_dur2=$(grep "write " $tmp_dir/ior_hard | tail -n 1 | awk '{print $10}')
print_bw 2 $bw2 $bw_dur2 | tee -a $ior_results_file


#mdtest hard create
cd $workdir/mdt_hard
mkdir tmp
$mpirun mdtest -v -C -d ${workdir}/mdt_hard/tmp -n $mdtest_hard_files_per_proc -w 3900 | tee $tmp_dir/mdt_hard
iops2=$(grep "File creation"  $tmp_dir/mdt_hard | tail -n 1 | awk '{print $4}')
print_iops 2 $iops2 | tee -a $mdt_results_file


# ior easy read
cd $workdir/ior_easy
$mpirun IOR -F -e -g -vv -R -r -C -G 27 -k -t 512k -b 3195392k -o ${workdir}/ior_easy/ior_file_easy | tee $tmp_dir/ior_read_easy
bw3=$(grep "Max R" $tmp_dir/ior_read_easy | sed 's\(\\g' | sed 's\)\\g' | tail -n 1 | awk '{print $5}')

bw_dur3=$(grep "read " $tmp_dir/ior_read_easy | tail -n 1 | awk '{print $10}')
print_bw 3 $bw3 $bw_dur3 | tee -a $ior_results_file


# mdtest easy stat
cd $workdir/mdt_easy
mkdir tmp
$mpirun mdtest -v -T -d ${workdir}/mdt_easy/tmp -u -n $mdtest_hard_files_per_proc | tee $tmp_dir/mdt_read_easy
iops3=$(grep "File stat" $tmp_dir/mdt_read_easy | tail -n 1 | awk '{print $4}')
print_iops 3 $iops3 | tee -a $mdt_results_file



# ior hard read
cd $workdir/ior_hard
$mpirun IOR  -g -vv -R -r -C -G 27 -k -t 47000 -b 47000 -s $ior_hard_writes_per_proc -o ${workdir}/ior_hard/IOR_file | tee $tmp_dir/ior_read_hard
bw4=$(grep "Max R" $tmp_dir/ior_read_hard | sed 's\(\\g' | sed 's\)\\g' | tail -n 1| awk '{print $5}')

bw_dur4=$(grep "read " $tmp_dir/ior_read_hard | tail -n 1 | awk '{print $10}')

print_bw 4 $bw4 $bw_dur4 | tee -a $ior_results_file


# mdtest hard stat
cd $workdir/mdt_hard
$mpirun mdtest -v -T -d ${workdir}/mdt_hard/tmp -n $mdtest_hard_files_per_proc    | tee $tmp_dir/mdt_read_hard
iops4=$(grep "File stat" $tmp_dir/mdt_read_hard | tail -n 1 | awk '{print $4}')
print_iops 4 $iops4 | tee -a $mdt_results_file



echo "Executing find command"
start=$(date +%s.%N)
time find ${workdir} -name \*00\* -newer ${workdir}/$ts2  -size +3000c | wc
end=$(date +%s.%N)
export duration=$(echo "scale=2; $end - $start" | bc)

searched_files1=$(grep "files/directories" $tmp_dir/mdt_hard | tail -n 1 | awk '{print $3*2}')
searched_files2=$(grep "files/directories" $tmp_dir/mdt_easy | tail -n 1 | awk '{print $3*2}')

# we figure out how many files are searched by 'find' by grepping the results of the mdtests
# we know that ior_hard is just one file
# we check of the access to IOR easy is file-per-proc to know the number of the files
let searched_files=$searched_files1+$searched_files2+1+$ior_easy_files

export iops5=$( echo "$searched_files/$duration" |bc )
#echo $find_ops >> mdtest_${SLURM_JOBID}

bw_score=`echo $bw1 $bw2 $bw3 $bw4 | awk '{print ($1*$2*$3*$4)^(1/4)}'`
md_score=`echo $iops1 $iops2 $iops3 $iops4 $iops5 | awk '{print ($1*$2*$3*$4*$5)^(1/5)}'`
export final_score=$( echo "$bw_score*$md_score" | bc)


echo -e "\nTotal score is "$final_score
