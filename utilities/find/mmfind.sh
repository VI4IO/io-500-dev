#! /bin/bash

# need to find and set the path to your mmfind executable, also path to a temp file for the log
mmfind=/path/to/mmfs/samples/ilm/mmfind 
logfile=/dev/shm/tmp.log
$mmfind -logLvl 2 -logFile $logfile $* 
total_files=$(grep -i  -e "Directories scan:" $logfile |awk {'printf $4'})
match_files=$(grep -i -A2  -e "Summary of Rule Applicability" $logfile |grep RULE |awk {'printf $2'})

echo "MATCHED $match_files/$total_files"
