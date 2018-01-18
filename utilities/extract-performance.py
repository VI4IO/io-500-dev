#!/usr/bin/env python

# This script extracts the performance values of one or multiple IO-500 run directories
# and converts them into a CSV file
import sys
import csv
import re

if len(sys.argv) == 1:
  print("Synopsis: %s [IO500 output dir] [IO500 output dir] ..." % (sys.argv[0]) )
  print("Example: %s results/*" %  (sys.argv[0]))
  exit(1)

def parseDir(d):
  """Parse the output of of a single IO500 results directory"""
  print("Parsing: %s " % (d))
  keyset = {}
  with open(d + "/result_summary.txt", "r") as results_file:
    for line in results_file:
      m = re.match(".*[ ]+([a-z_]+)[ ]*([0-9\.]+) (GB/s|kiops)", line)
      if m:
        keyset[m.group(1)] = m.group(2)
  return keyset


if __name__ == "__main__":
  print("Writing output to io500.csv")

  keys = ["ior_easy_write" , "mdtest_easy_write" , "ior_hard_write" , "mdtest_hard_write" , "find" , "ior_easy_read" , "mdtest_easy_stat" , "ior_hard_read" , "mdtest_hard_stat" , "mdtest_easy_delete" , "mdtest_hard_read" , "mdtest_hard_delete"]

  with open('io500.csv', 'w') as csvfile:
    csvwriter = csv.writer(csvfile, quoting=csv.QUOTE_ALL)
    csvwriter.writerow(["directory"] + keys)
    # Iterate over all arguments, each is handled as a directory
    for d in sys.argv[1:]:
      keyset = parseDir(d)
      row = [d]
      for k in keys:
        row.append(keyset[k])
      csvwriter.writerow(row)
