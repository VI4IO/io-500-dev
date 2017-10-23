#! /bin/bash

searchdir=$1
timestamp_file=$2
target_size=$3
target_string=$4

# you can replace this with whatever you want.  You will almost surely want to because this will be really slow for large number of files.
# Whatever you do, you just need to accept three parameters: the directory to recursively search and a filename and a target size.  Stat the file, and
# filter to only match files in the directory tree that are newer than it.
# Also only match files that have target_string in the name and are target_size bytes big
# Be completely silent except for printing 'x/y' when you are done where x is matched files and y is total files searched.
# There are a few parallel find commands './utilities/find' directory that might be useful.

function parse_rates {
  #find -D rates gives a weird thing like this:
  #Predicate success rates after completion
  # (  ( -name *01* [0.8] [602/30415=0.0197929] -a [0.008] [308/30415=0.0101266] [call stat] [need type] -newer /Users/jbent/io-500-dev/datafiles/io500.2017.10.21-21.05.56/timestampfile [0.01] [308/602=0.511628]  ) -a [8e-05] [308/30415=0.0101266] [call stat] -size 3900 [0.01] [308/308=1]  ) -a [8e-05] [308/30415=0.0101266] -print [1] [308/308=1] 
  # so if we parse out the first 602/30415, we can get 30415 as the total number of files searched
  # and if we parse out the final 308/308, we can get 308 as the total number of files matched 
  echo $rates | tr " " "\n" | grep '/' | $1 -1 | cut -d \/ -f 2 | cut -d = -f 1
}

rates=`find -D rates $searchdir -name '*'$target_string'*' -newer $timestamp_file -size ${target_size}c 2>&1 | grep -A1 Predicate | tail -1` 
total_files=$(parse_rates 'head')
match_files=$(parse_rates 'tail')
echo "$match_files/$total_files"
