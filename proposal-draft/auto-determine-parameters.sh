#!/bin/bash -e

# This script automatically identifies the parameters for the IO-500 benchmark
# It will determine the number of directories, files and data for the creation phase and the find.

if [[ "$workdir" == "" ]] ; then
	echo "Invalid workdir!"
	exit 1
fi

## Do not change the script below this point except for testing...
timeExpected=100       # 300 seconds
timeThreshhold=50   # 100 seconds

subtree_to_scan_config=$PWD/subtree.cfg

function createSubtree(){
	count="$1"
	# The subtrees to scan from md-easy, each contains mdtest_easy_files_per_proc files
	( for I in $(seq $count) ; do
	echo mdtest_tree.$(($I-1)).0
	done ) > subtree.cfg
}

# Initial settings
ior_easy_params="-t 2048k -b 2048k -s 1"
ior_hard_writes_per_proc=1
mdtest_hard_files_per_proc=1
mdtest_easy_files_per_proc=1

createSubtree 1

function run() {
	source io_500_core.sh
	rm -rf $workdir/*/* || true
}

function adaptParameter(){
	timefile=$1
	currentValue=$2
	time=$(cat $output_dir/$timefile | cut -d ":" -f 3 | cut -d "s" -f 1 | head -n 1)

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
	echo $(($currentValue * 2)) # simply double the files/amount of data...
}

# initial clean of existing directories
rm -rf $workdir/*/* || true

# initial run to calibrate
echo "Calibrating run"
run

if [[ "$identify_parameters_ior_easy" == "True" ]] ; then
	echo "Tuning IOR easy"
	# adapt the ior-easy parameters
	count=1
	while true ; do
		newCount=$(adaptParameter ior-easy-results.txt $count)
		if [[ $count == $newCount ]] ; then
			break
		fi
		count=$newCount

		ior_easy_params="-t 2m -b ${count}m"
		echo ior_easy_params="$ior_easy_params"
		run
	done

	# remember best setting
	ior_easy_params_tmp=$ior_easy_params
	echo "ior_easy_params=$ior_easy_params_tmp"
	ior_easy_params="-t 2048k -b 2048k -s 1"
fi


if [[ "$identify_parameters_ior_hard" == "True" ]] ; then
	# adapt the ior-hard parameters
	count=1
	echo "Tuning IOR hard"
	while true ; do
		newCount=$(adaptParameter ior-hard-results.txt $count)
		if [[ $count == $newCount ]] ; then
			break
		fi
		count=$newCount
		ior_hard_writes_per_proc="${count}"
		echo ior_hard_writes_per_proc="$ior_hard_writes_per_proc"
		run
	done
	# remember settings
	ior_hard_writes_per_proc_tmp=$ior_hard_writes_per_proc
	echo "ior_hard_writes_per_proc=$ior_hard_writes_per_proc_tmp"
	ior_hard_writes_per_proc="1"
fi


if [[ "$identify_parameters_mdt_easy" == "True" ]] ; then
	# adapt the md-easy parameters
	echo "Tuning md-easy"
	count=1
	while true ; do
		newCount=$(adaptParameter mdt-easy-results.txt $count)
		if [[ $count == $newCount ]] ; then
			break
		fi
		count=$newCount
		mdtest_easy_files_per_proc="${count}"
		echo mdtest_easy_files_per_proc=$mdtest_easy_files_per_proc
		run
	done

	# remember settings
	mdtest_easy_files_per_proc_tmp=$mdtest_easy_files_per_proc
	echo "mdtest_easy_files_per_proc=$mdtest_easy_files_per_proc_tmp"
        # no tuning of find needed

	mdtest_easy_files_per_proc="1"
fi

if [[ "$identify_parameters_mdt_hard" == "True" ]] ; then
	echo "Tuning MD-hard"
	# adapt the md-hard parameters
	count=1
	while true ; do
		newCount=$(adaptParameter mdt-hard-results.txt $count)
		if [[ $count == $newCount ]] ; then
			break
		fi
		count=$newCount
		mdtest_hard_files_per_proc="${count}"
		echo mdtest_hard_files_per_proc=$mdtest_hard_files_per_proc
		run
	done

	# remember settings
	mdtest_hard_files_per_proc_tmp=$mdtest_hard_files_per_proc
	echo "mdtest_hard_files_per_proc=$mdtest_hard_files_per_proc"
	mdtest_hard_files_per_proc="1"
fi


# final parameters:
echo ""
echo "ior_easy_params=$ior_easy_params_tmp"
echo "ior_hard_writes_per_proc=$ior_hard_writes_per_proc_tmp"
echo "mdtest_hard_files_per_proc=$mdtest_hard_files_per_proc_tmp"
echo "mdtest_easy_files_per_proc=$mdtest_easy_files_per_proc_tmp"
echo "subtree_to_scan_config=$PWD/subtree.cfg"
echo ""
