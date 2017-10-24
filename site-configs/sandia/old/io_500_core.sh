#!/bin/bash -e
#IO-500 benchmark
# don't edit

export LC_NUMERIC=C  # prevents printf errors

# check variables
if [[ "$find_subtree_to_scan_config" == "" || "$workdir" == "" || "$ior_easy_params" == "" || "$mdtest_hard_files_per_proc" == "" || "$ior_hard_writes_per_proc" == "" || "$find_cmd" == "" || "$ior_cmd" == ""  || "$mdtest_cmd" == ""  ]] ; then
	echo "IO500 script lacks important paramaters!"
	exit 1
fi
#

echo "[Precreating] missing directories"
mkdir -p $workdir/ior_easy $workdir/mdt_easy  $workdir/mdt_hard $workdir/ior_hard $workdir/mdreal $result_dir  2>/dev/null

function print_bw  {
   echo "$1/$phase BW:$2 MB/s time: ${duration}s"
}

function print_iops  {
   echo "$1/$phase IOPs:$2 time:${duration}s"
}

function startphase {
  echo "[Starting] $phase"
  start=$(date +%s.%N)
}

#function endphase  {
#  r=$?
#  if [[ "$r" != "0" ]] ; then
#     echo "Error: the benchmark returned $r"
#     exit 1
#  fi
#  end=$(date +%s.%N)
#  duration=$(printf "%.0f" $(echo "scale=2; $end - $start" | bc))
#}

function endphase_check  {
  r=$?
  if [[ "$r" != "0" ]] ; then
     echo "Error: the benchmark returned $r"
     exit 1
  fi
  end=$(date +%s.%N)
  duration=$(printf "%.0f" $(echo "scale=2; $end - $start" | bc))
  if [[ $duration -le 300 ]] ; then
	echo "[Warning]: the runtime is below 5 minutes"
  fi
}

params_ior_hard="-C -Q 1 -g -G 27 -k -vv -e -t 47000 -b 47000 -s $ior_hard_writes_per_proc -o ${workdir}/ior_hard/IOR_file" # -W (validation) NOT for testing runtime
params_ior_easy="-C -Q 1 -g -G 27 -k -vv -e -F $ior_easy_params -o $workdir/ior_easy/ior_file_easy" # -W (validation) NOT for testing runtime
params_md_easy="-v -u -L -F -d ${workdir}/mdt_easy -u -n $mdtest_easy_files_per_proc"
params_md_hard="-t -F -w 3900 -e 3900 -d ${workdir}/mdt_hard -n $mdtest_hard_files_per_proc"
mdreal_params="-I=3 -L=$result_dir/mdreal -D=1 $mdreal_params  -- -D=${workdir}/mdreal"

touch $workdir/timestamp

### IOR EASY WRITE
if [[ "$run_ior_easy" != "False" ]] ; then
  phase="ior-easy-write"
  startphase
  $mpirun $ior_cmd -w $params_ior_easy > $result_dir/ior_easy_write 2>&1
  endphase_check
  bw1=$(grep "Max W" $result_dir/ior_easy_write | sed 's/^.*(//g' | sed 's/).*$//g' | tail -n 1 | awk '{print $1}')

  bw_dur1=$(grep "write " $result_dir/ior_easy_write | tail -n 1 | awk '{print $10}')
  print_bw 1 $bw1 $bw_dur1 | tee   $result_dir/ior-easy-results.txt
  ## NOTE: CLEANUP AT THE END OF THE SCRIPT
fi

### MDTEST EASY CREATE
if [[ "$run_md_easy" != "False" ]] ; then
  phase="md-easy-create"
  startphase
  $mpirun $mdtest_cmd -C $params_md_easy > $result_dir/mdt_easy_create 2>&1
  endphase_check
  iops1=$(grep "File creation" $result_dir/mdt_easy_create | tail -n 1 | awk '{print $4}')
  print_iops 1 $iops1 | tee  $result_dir/mdt-easy-results.txt
fi

### IOR HARD CREATE
if [[ "$run_ior_hard" != "False" ]] ; then
  phase="ior-hard-write"
  startphase
  $mpirun $ior_cmd -w $params_ior_hard > $result_dir/ior_hard_write 2>&1
  endphase_check
  bw2=$(grep "Max W" $result_dir/ior_hard_write | sed 's/^.*(//g' | sed 's/).*$//g' | tail -n 1 | awk '{print $1}')

  bw_dur2=$(grep "write " $result_dir/ior_hard_write | tail -n 1 | awk '{print $10}')
  print_bw 2 $bw2 $bw_dur2 | tee $result_dir/ior-hard-results.txt
  ## NOTE: CLEANUP AT THE END OF THE SCRIPT
fi

### MDTEST HARD CREATE
if [[ "$run_md_hard" != "False" ]] ; then
  phase="md-hard-create"
  startphase
  $mpirun $mdtest_cmd -C  $params_md_hard > $result_dir/mdt_hard_create 2>&1
  endphase_check

  iops2=$(grep "File creation"  $result_dir/mdt_hard_create | tail -n 1 | awk '{print $4}')
  print_iops 2  $iops2 | tee $result_dir/mdt-hard-results.txt
fi

### IOR EASY READ
if [[ "$run_ior_easy" != "False" && "$run_ior_easy_read" != "False" ]] ; then
  phase="ior-easy-read"
  startphase
  $mpirun $ior_cmd -r -C $params_ior_easy > $result_dir/ior_easy_read 2>&1
  endphase_check
  bw3=$(grep "Max R" $result_dir/ior_easy_read | sed 's/^.*(//g' | sed 's/).*$//g' | tail -n 1 | awk '{print $1}')

  bw_dur3=$(grep "read " $result_dir/ior_easy_read | tail -n 1 | awk '{print $10}')
  print_bw 3 $bw3 $bw_dur3 | tee -a $result_dir/ior-easy-results.txt
fi

### MDTEST EAST STAT
if [[ "$run_md_easy" != "False" && "$run_md_easy_read" != "False" ]] ; then
  phase="md-easy-stat"
  startphase
  $mpirun $mdtest_cmd -T $params_md_easy > $result_dir/mdt_easy_stat
  endphase_check
  iops3=$(grep "File stat" $result_dir/mdt_easy_stat | tail -n 1 | awk '{print $4}')
  print_iops 3 $iops3 | tee -a $result_dir/mdt-easy-results.txt
fi

### IOR HARD READ
if [[ "$run_ior_hard" != "False" && "$run_ior_hard_read" != "False" ]] ; then
  phase="ior-hard-read"
  startphase
  $mpirun $ior_cmd  -r -C $params_ior_hard > $result_dir/ior_hard_read 2>&1 # later use -R once fixed...
  endphase_check
  bw4=$(grep "Max R" $result_dir/ior_hard_read | sed 's/^.*(//g' | sed 's/).*$//g' | tail -n 1| awk '{print $1}')
  bw_dur4=$(grep "read " $result_dir/ior_hard_read | tail -n 1 | awk '{print $10}')
  print_bw 4 $bw4 $bw_dur4 | tee -a $result_dir/ior-hard-results.txt
fi

### MDTEST HARD STAT
if [[ "$run_md_hard" != "False" && "$run_md_hard_read" != "False" ]] ; then
  phase="md-hard-stat"
  startphase
  $mpirun $mdtest_cmd -T $params_md_hard   > $result_dir/mdt_hard_stat 2>&1
  endphase_check
  iops4=$(grep "File stat" $result_dir/mdt_hard_stat | tail -n 1 | awk '{print $4}')
  print_iops 4 $iops4 | tee -a $result_dir/mdt-hard-results.txt
fi

### FIND (PARALLEL)
if [[ "$run_pfind" == "True" && "$run_md_easy" != "False" ]] ; then
  phase="find (parallel)"
  find_procs=`wc -l < $find_subtree_to_scan_config`
  startphase
  $mpirun_pfind -n $find_procs pfind $find_cmd $workdir/timestamp $workdir/mdt_easy/#test-dir.0/    > $result_dir/find_re 2>&1
  endphase_check
  found=0
  for ((i=1;i<=$find_procs;i++)); do found=$(($found + $(cat $workdir/mdt_easy/$i))); done;
  iops5=`echo "$found/$duration" |bc`
  print_iops 5 $iops5 | tee $result_dir/find-results.txt
fi

### FIND (SERIAL)
if [[ "$run_find" != "False" && "$run_md_easy" != "False" ]] ; then
  phase="find (serial)"
  startphase
  iops5=$($find_cmd $workdir/timestamp $workdir/mdt_easy/#test-dir.0/ $find_subtree_to_scan_config)
  endphase_check
  print_iops 5 $iops5 | tee $result_dir/find-results.txt
fi

### MDTEST EASY DELETE
if [[ "$run_md_easy" != "False" ]] ; then
  phase="md-easy-delete"
  startphase
  $mpirun $mdtest_cmd -r $params_md_easy > $result_dir/mdt_easy_delete 2>&1
  endphase_check
  iops6=$(grep "File removal" $result_dir/mdt_easy_delete | tail -n 1 | awk '{print $4}')
  print_iops 6 $iops6 | tee -a $result_dir/mdt-easy-results.txt
fi

### MDTEST HARD DELETE
if [[ "$run_md_hard" != "False" ]] ; then
  phase="md-hard-delete"
  startphase
  $mpirun $mdtest_cmd -r $params_md_hard   > $result_dir/mdt_hard_delete 2>&1
  endphase_check
  iops7=$(grep "File removal" $result_dir/mdt_hard_delete | tail -n 1 | awk '{print $4}')
  print_iops 7 $iops7 | tee -a $result_dir/mdt-hard-results.txt
fi

### MDREALIO
if [[ $mdreal_cmd != "" ]] ; then
	phase="md-real-io"
	startphase
	$mpirun $mdreal_cmd $mdreal_params > $result_dir/mdreal 2>&1
	endphase_check
	iops8=$( grep "^benchmark" $result_dir/mdreal | tail -n 1 | awk '{print $3}' ) # obj/s
	bw5=$( grep "^benchmark" $result_dir/mdreal | tail -n 1 | awk '{print $9}' ) # in MiB/s
	print_iops 8 $iops8 | tee -a $result_dir/mdreal-results.txt
fi

echo "bw1=$bw1		ior-easy-write"
echo "iops1=$iops1		md-easy-create"
echo "bw2=$bw2		ior-hard-write"
echo "iops2=$iops2		md-hard-create"
echo "bw3=$bw3		ior-easy-read"
echo "iops3=$iops3		md-easy-stat"
echo "bw4=$bw4		ior-hard-read"
echo "iops4=$iops4		md-hard-stat"
echo "iops5=$iops5		find (parallel or serial)"
echo "iops6=$iops6		md-easy-delete"
echo "iops7=$iops7		md-hard-delete"

if [[ $mdreal_cmd != "" ]] ; then
    echo "Not included in final score"
    echo "bw5=$bw5		md-real-bw"
    echo "iops8=$iops8		md-real-iops"
fi

bw_score=`echo $bw1 $bw2 $bw3 $bw4 | awk '{print ($1*$2*$3*$4)^(1/4)}'`
md_score=`echo $iops1 $iops2 $iops3 $iops4 $iops5 $iops6 $iops7 | awk '{print ($1*$2*$3*$4*$5*$6*$7)^(1/7)}'`

echo
echo "IO-500 bw score: $bw_score MB/s"
echo "IO-500 md score: $md_score IOPS"
export final_score=$( echo "$bw_score*$md_score" | bc)
echo
echo "IO-500 score: " $final_score

rm $workdir/ior_easy/ior_file_easy* $workdir/ior_hard/IOR_file
rmdir $workdir/ior_easy $workdir/mdt_easy  $workdir/mdt_hard $workdir/ior_hard $workdir/mdreal
rm $workdir/timestamp
