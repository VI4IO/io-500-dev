#!/bin/bash -e

# This script automatically identifies the parameters based on the following directories:

if [[ "$workdir" == "" ]] ; then
	echo "Invalid workdir!"
	exit 1
fi

## Do not change the script below this point except for testing...
timeExpected=300       # 300 seconds
timeThreshhold=100   # 100 seconds

subtree_to_scan_config=$PWD/subtree.cfg

function createSubtree(){
	count="$1"
	# The subtrees to scan from md-easy, each contains mdtest_easy_files_per_proc files
	( for I in $(seq $count) ; do 
	echo mdtest_tree.$(($I-1)).0
	done ) > subtree.cfg
}

# Initial settings
ior_easy_params="-t 2048k -b 204800k"
ior_hard_writes_per_proc=1              
mdtest_hard_files_per_proc=1           
mdtest_easy_files_per_proc=1
rm output || true

createSubtree 1

function run() {
	echo "Running "
	(
	echo ""
	echo $ior_easy_params
	echo $ior_hard_writes_per_proc
	echo $mdtest_hard_files_per_proc
	echo $mdtest_easy_files_per_proc
	source io_500_core.sh 
	) 1>>output 2>&1 
	rm -rf $workdir/*/* || true
}

function adaptParameter(){
	timefile=$1
	currentValue=$2
	time=$(cat $output_dir/$timefile | cut -d ":" -f 3 | cut -d "s" -f 1 | sort -n | head -n 1)
	
	if [[ $time -lt 1 ]] ; then
		echo $(($currentValue * 100))
		return
	fi
	if [[ $time -gt $timeExpected ]] ; then 
		echo $(($currentValue)) # use the current value
		return
	fi
	if [[ $time -lt $timeThreshhold ]] ; then 
		echo $(($currentValue * $timeExpected/$time)) 
		return
	fi
	echo $(($currentValue * 2)) # simply double the files...
}

# initial clean of existing directories
rm -rf $workdir/*/* || true

# initial run to calibrate
run

# adapt the ior-easy parameters
count=2048
while true ; do
	newCount=$(adaptParameter ior-easy-results.txt $count)
	if [[ $count == $newCount ]] ; then
		break
	fi
	count=$newCount
	ior_easy_params="-t 2048k -b ${count}k"
	run
done

# remember best setting
ior_easy_params_tmp=$ior_easy_params
echo "ior_easy_params=$ior_easy_params_tmp"
ior_easy_params="-t 2048k -b 2048k"



# adapt the ior-hard parameters
count=1
while true ; do
	newCount=$(adaptParameter ior-hard-results.txt $count)
	if [[ $count == $newCount ]] ; then
		break
	fi
	count=$newCount
	ior_hard_writes_per_proc="${count}"
	run
done
# remember settings
ior_hard_writes_per_proc_tmp=$ior_hard_writes_per_proc
echo "ior_hard_writes_per_proc=$ior_hard_writes_per_proc_tmp"
ior_hard_writes_per_proc="1"



# adapt the md-easy parameters
count=1
while true ; do
	newCount=$(adaptParameter mdt-easy-results.txt $count)
	if [[ $count == $newCount ]] ; then
		break
	fi
	count=$newCount
	mdtest_easy_files_per_proc="${count}"
	run
done

# remember settings
mdtest_easy_files_per_proc_tmp=$mdtest_easy_files_per_proc
echo "mdtest_easy_files_per_proc=$mdtest_easy_files_per_proc_tmp"
mdtest_easy_files_per_proc="1"


# adapt the md-hard parameters
count=1
while true ; do
	newCount=$(adaptParameter mdt-hard-results.txt $count)
	if [[ $count == $newCount ]] ; then
		break
	fi
	count=$newCount
	mdtest_hard_files_per_proc="${count}"
	run
done

# remember settings
mdtest_hard_files_per_proc_tmp=$mdtest_hard_files_per_proc
echo "mdtest_hard_files_per_proc=$mdtest_hard_files_per_proc"
mdtest_hard_files_per_proc="1"


# adapt the find parameters
mdtest_easy_files_per_proc=$mdtest_easy_files_per_proc_tmp

count=1
while true ; do
	newCount=$(adaptParameter mdt-hard-results.txt $count)
	if [[ $count == $newCount ]] ; then
		break
	fi
	count=$newCount
	if [[ $count -gt $maxTasks ]] ; then
		echo "You have to manually increase the number of processes"
		echo "Find command is faster than 5 minutes!"
		exit 1
	fi

	createSubtree $count
	run
done


# final parameters:
echo ""
echo "ior_easy_params=$ior_easy_params_tmp"
echo "ior_hard_writes_per_proc=$ior_hard_writes_per_proc_tmp"
echo "mdtest_hard_files_per_proc=$mdtest_hard_files_per_proc_tmp"
echo "mdtest_easy_files_per_proc=$mdtest_easy_files_per_proc_tmp"
echo "subtree_to_scan_config=$PWD/subtree.cfg"

