#!/bin/bash -e
#IO-500 benchmark
# don't edit

# check variables
if [[ "$workdir" == "" || "$ior_easy_params" == "" || "$mdtest_hard_files_per_proc" == "" || "$ior_hard_writes_per_proc" == "" || "$find_cmd" == "" || "$ior_cmd" == ""  || "$mdtest_cmd" == ""  ]] ; then
	echo "IO500 script lacks important paramaters!"
	exit 1
fi 
# 

if [[ ! -d $workdir/ior_easy ]] ; then
	echo "Precreating missing directories"
	mkdir -p $workdir/ior_easy $workdir/mdt_easy  $workdir/mdt_hard $workdir/ior_hard $output_dir 2>/dev/null
fi

function print_bw  {
   echo "Bandwidth $1 is $2 MB/s and duration is $3 seconds" 
}

function print_iops  {
   echo "IOPs $1 is $2" 
}

# ior easy write
cd $workdir/ior_easy
$mpirun $ior_cmd -F -e -g -vv -w -G 27 -k $ior_easy_params -o $workdir/ior_easy/ior_file_easy > $output_dir/ior_easy 2>&1
bw1=$(grep "Max W" $output_dir/ior_easy | sed 's\(\\g' | sed 's\)\\g' | tail -n 1 | awk '{print $5}')

bw_dur1=$(grep "write " $output_dir/ior_easy | tail -n 1 | awk '{print $10}')
print_bw 1 $bw1 $bw_dur1 | tee   $output_dir/ior-easy-results.txt


grep -q "file-per-proc" $output_dir/ior_easy
if [ $? -eq 0 ]; then
	let ior_easy_files=$(($nodes*$procs_per_node))
else
	let ior_easy_files=1
fi 
#mdtest easy create
start=$(date +%s.%N)
$mpirun $mdtest_cmd -v -C -u -b 1 -L -d ${workdir}/mdt_easy -u -n $mdtest_easy_files_per_proc > $output_dir/mdt_easy 2>&1
end=$(date +%s.%N)
export duration=$(echo "scale=2; $end - $start" | bc)
iops1=$(grep "File creation" $output_dir/mdt_easy | tail -n 1 | awk '{print $4}')
print_iops 1 $iops1 | tee  $output_dir/mdt-easy-results.txt

echo "mdt easy create duration "$duration
touch $workdir/timestamp

# ior hard write
$mpirun $ior_cmd -e -g -vv -w -G 27 -k -t 47000 -b 47000 -s $ior_hard_writes_per_proc -o ${workdir}/ior_hard/IOR_file > $output_dir/ior_hard 2>&1
bw2=$(grep "Max W" $output_dir/ior_hard | sed 's\(\\g' | sed 's\)\\g' | tail -n 1 | awk '{print $5}')

bw_dur2=$(grep "write " $output_dir/ior_hard | tail -n 1 | awk '{print $10}')
print_bw 2 $bw2 $bw_dur2 | tee $output_dir/ior-hard-results.txt


#mdtest hard create
start=$(date +%s.%N)
$mpirun $mdtest_cmd -v -C -d ${workdir}/mdt_hard -n $mdtest_hard_files_per_proc -w 3900 > $output_dir/mdt_hard 2>&1
end=$(date +%s.%N)
export duration=$(echo "scale=2; $end - $start" | bc)
iops2=$(grep "File creation"  $output_dir/mdt_hard | tail -n 1 | awk '{print $4}')
print_iops 2 $iops2 | tee -a $output_dir/mdt-hard-results.txt

echo "mdt hard create duration "$duration

# ior easy read
$mpirun $ior_cmd -F -e -g -vv -R -r -C -G 27 -k $ior_easy_params -o ${workdir}/ior_easy/ior_file_easy >> $output_dir/ior_easy 2>&1
bw3=$(grep "Max R" $output_dir/ior_easy | sed 's\(\\g' | sed 's\)\\g' | tail -n 1 | awk '{print $5}')

bw_dur3=$(grep "read " $output_dir/ior_easy | tail -n 1 | awk '{print $10}')
print_bw 3 $bw3 $bw_dur3 | tee -a $output_dir/mdt-easy-results.txt


# mdtest easy stat
$mpirun $mdtest_cmd -v -T -u -b 1 -L -d ${workdir}/mdt_easy/ -u -n $mdtest_easy_files_per_proc >> $output_dir/mdt_easy
iops3=$(grep "File stat" $output_dir/mdt_easy | tail -n 1 | awk '{print $4}')
print_iops 3 $iops3 | tee -a $output_dir/mdt-easy-results.txt

# ior hard read
$mpirun $ior_cmd  -g -vv -R -r -C -G 27 -k -t 47000 -b 47000 -s $ior_hard_writes_per_proc -o ${workdir}/ior_hard/IOR_file >> $output_dir/ior_hard 2>&1
bw4=$(grep "Max R" $output_dir/ior_hard | sed 's\(\\g' | sed 's\)\\g' | tail -n 1| awk '{print $5}')

bw_dur4=$(grep "read " $output_dir/ior_hard | tail -n 1 | awk '{print $10}')
print_bw 4 $bw4 $bw_dur4 | tee -a $output_dir/ior-hard-results.txt


# mdtest hard stat
$mpirun $mdtest_cmd -v -T -d ${workdir}/mdt_hard -n $mdtest_hard_files_per_proc    >> $output_dir/mdt_hard 2>&1
iops4=$(grep "File stat" $output_dir/mdt_hard | tail -n 1 | awk '{print $4}')
print_iops 4 $iops4 | tee -a $output_dir/mdt-hard-results.txt


echo "Executing the find command"
searched_files1=$(grep "files/directories" $output_dir/mdt_hard | tail -n 1 | awk '{print $3*2}')
searched_files2=$(grep "files/directories" $output_dir/mdt_easy | tail -n 1 | awk '{print $3*2}')

# we figure out how many files are searched by 'find' by grepping the results of the mdtests
# we know that ior_hard is just one file
# we check of the access to IOR easy is file-per-proc to know the number of the files
#let searched_files=$searched_files1+$searched_files2+1+$ior_easy_files

iops5=$($find_cmd $workdir)
print_iops 5 $iops5 | tee -a $output_dir/find-results.txt 

# cleanup phase
# mdtest easy remove
$mpirun $mdtest_cmd -v -r -u -b 1 -L -d ${workdir}/mdt_easy/ -u -n $mdtest_easy_files_per_proc >> $output_dir/mdt_easy 2>&1
iops6=$(grep "File removal" $output_dir/mdt_easy | tail -n 1 | awk '{print $4}')
print_iops 6 $iops6 | tee -a $output_dir/mdt-easy-results.txt

# mdtest hard remove
$mpirun $mdtest_cmd -v -r -d ${workdir}/mdt_hard -n $mdtest_hard_files_per_proc    >> $output_dir/mdt_hard 2>&1
iops7=$(grep "File removal" $output_dir/mdt_hard | tail -n 1 | awk '{print $4}')
print_iops 7 $iops7 | tee -a $output_dir/mdt-hard-results.txt


bw_score=`echo $bw1 $bw2 $bw3 $bw4 | awk '{print ($1*$2*$3*$4)^(1/4)}'`
md_score=`echo $iops1 $iops2 $iops3 $iops4 $iops6 $iops7 $iops5 | awk '{print ($1*$2*$3*$4*$5*$6*$7)^(1/7)}'`
export final_score=$( echo "$bw_score*$md_score" | bc)


echo -e "\nTotal score is "$final_score

