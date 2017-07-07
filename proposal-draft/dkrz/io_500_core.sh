#!/bin/bash -e
#IO-500 benchmark
# don't edit

export LC_NUMERIC=C  # prevents printf errors

# check variables
if [[ "$subtree_to_scan_config" == "" || "$workdir" == "" || "$ior_easy_params" == "" || "$mdtest_hard_files_per_proc" == "" || "$ior_hard_writes_per_proc" == "" || "$find_cmd" == "" || "$ior_cmd" == ""  || "$mdtest_cmd" == ""  ]] ; then
	echo "IO500 script lacks important paramaters!"
	exit 1
fi 
# 

echo "[Precreating] missing directories"
mkdir -p $workdir/ior_easy $workdir/mdt_easy  $workdir/mdt_hard $workdir/ior_hard $output_dir 2>/dev/null

function print_bw  {
   echo "$1/$phase BW:$2 MB/s time: ${3}s" 
}

function print_iops  {
   echo "$1/$phase IOPs:$2 time:${duration}s" 
}

function startphase {
  echo "[Starting] $phase"
  start=$(date +%s.%N)
}

function endphase  {  
  end=$(date +%s.%N)
  duration=$(printf "%.0f" $(echo "scale=2; $end - $start" | bc))
  if [[ $duration -le 300 ]] ; then
	echo "[Warning]: the runtime is below 5 minutes"
  fi
}

params_ior_hard="-C -Q 1 -g -G 27 -k -vv -e -t 47000 -b 47000 -s $ior_hard_writes_per_proc -o ${workdir}/ior_hard/IOR_file" # -W (validation) NOT for testing runtime
params_ior_easy="-C -Q 1 -g -G 27 -k -vv -e -F $ior_easy_params -o $workdir/ior_easy/ior_file_easy" # -W (validation) NOT for testing runtime
params_md_easy="-v -u -b 1 -L -d ${workdir}/mdt_easy -u -n $mdtest_easy_files_per_proc"
params_md_hard="-d ${workdir}/mdt_hard -n $mdtest_hard_files_per_proc -w 3900 -e 3900"

touch $workdir/timestamp

# ior easy write
phase="ior-easy-write"
startphase
$mpirun $ior_cmd -w $params_ior_easy > $output_dir/ior_easy 2>&1
endphase   
bw1=$(grep "Max W" $output_dir/ior_easy | sed 's\(\\g' | sed 's\)\\g' | tail -n 1 | awk '{print $5}')

bw_dur1=$(grep "write " $output_dir/ior_easy | tail -n 1 | awk '{print $10}')
print_bw 1 $bw1 $bw_dur1 | tee   $output_dir/ior-easy-results.txt

#mdtest easy create
phase="md-easy-create"
startphase
$mpirun $mdtest_cmd -C $params_md_easy > $output_dir/mdt_easy 2>&1
endphase  
iops1=$(grep "File creation" $output_dir/mdt_easy | tail -n 1 | awk '{print $4}')
print_iops 1 $iops1 | tee  $output_dir/mdt-easy-results.txt

# ior hard write
phase="ior-hard-write"
startphase
$mpirun $ior_cmd -w $params_ior_hard > $output_dir/ior_hard 2>&1
endphase  
bw2=$(grep "Max W" $output_dir/ior_hard | sed 's\(\\g' | sed 's\)\\g' | tail -n 1 | awk '{print $5}')

bw_dur2=$(grep "write " $output_dir/ior_hard | tail -n 1 | awk '{print $10}')
print_bw 2 $bw2 $bw_dur2 | tee $output_dir/ior-hard-results.txt


#mdtest hard create
phase="md-hard-create"
startphase
$mpirun $mdtest_cmd -C  $params_md_hard > $output_dir/mdt_hard 2>&1
endphase  

iops2=$(grep "File creation"  $output_dir/mdt_hard | tail -n 1 | awk '{print $4}')
print_iops 2  $iops2 | tee -a $output_dir/mdt-hard-results.txt


# ior easy read
phase="ior-easy-read"
startphase
$mpirun $ior_cmd -R -r -C $params_ior_easy >> $output_dir/ior_easy 2>&1
endphase  
bw3=$(grep "Max R" $output_dir/ior_easy | sed 's\(\\g' | sed 's\)\\g' | tail -n 1 | awk '{print $5}')

bw_dur3=$(grep "read " $output_dir/ior_easy | tail -n 1 | awk '{print $10}')
print_bw 3 $bw3 $bw_dur3 | tee -a $output_dir/ior-easy-results.txt


# mdtest easy stat
phase="md-easy-stat"
startphase
$mpirun $mdtest_cmd -T $params_md_easy >> $output_dir/mdt_easy
endphase  
iops3=$(grep "File stat" $output_dir/mdt_easy | tail -n 1 | awk '{print $4}')
print_iops 3 $iops3 | tee -a $output_dir/mdt-easy-results.txt

# ior hard read
phase="md-hard-read"
startphase
$mpirun $ior_cmd  -R -r -C $params_ior_hard >> $output_dir/ior_hard 2>&1
endphase  
bw4=$(grep "Max R" $output_dir/ior_hard | sed 's\(\\g' | sed 's\)\\g' | tail -n 1| awk '{print $5}')
bw_dur4=$(grep "read " $output_dir/ior_hard | tail -n 1 | awk '{print $10}')
print_bw 4 $bw4 $bw_dur4 | tee -a $output_dir/mdt-hard-results.txt


# mdtest hard stat
phase="md-hard-stat"
startphase
$mpirun $mdtest_cmd -T $params_md_hard   >> $output_dir/mdt_hard 2>&1
endphase  
iops4=$(grep "File stat" $output_dir/mdt_hard | tail -n 1 | awk '{print $4}')
print_iops 4 $iops4 | tee -a $output_dir/mdt-hard-results.txt

# find
phase="find"
startphase
iops5=$($find_cmd $workdir/timestamp $workdir/mdt_easy/#test-dir.0/ $subtree_to_scan_config)
endphase  
print_iops 5 $iops5 | tee $output_dir/find-results.txt 

# cleanup phase
# mdtest easy remove
phase="md-easy-delete"
startphase
$mpirun $mdtest_cmd -r $params_md_easy >> $output_dir/mdt_easy 2>&1
endphase  
iops6=$(grep "File removal" $output_dir/mdt_easy | tail -n 1 | awk '{print $4}')
print_iops 6 $iops6 | tee -a $output_dir/mdt-easy-results.txt

# mdtest hard remove
phase="md-hard-delete"
startphase
$mpirun $mdtest_cmd -r $params_md_hard   >> $output_dir/mdt_hard 2>&1
endphase  
iops7=$(grep "File removal" $output_dir/mdt_hard | tail -n 1 | awk '{print $4}')
print_iops 7 $iops7 | tee -a $output_dir/mdt-hard-results.txt


bw_score=`echo $bw1 $bw2 $bw3 $bw4 | awk '{print ($1*$2*$3*$4)^(1/4)}'`
md_score=`echo $iops1 $iops2 $iops3 $iops4 $iops6 $iops7 $iops5 | awk '{print ($1*$2*$3*$4*$5*$6*$7)^(1/7)}'`
echo
echo "IO-500 bw score: $bw_score MB/s"
echo "IO-500 md score: $md_score IOPS"
export final_score=$( echo "$bw_score*$md_score" | bc)
echo
echo "IO-500 score: " $final_score

