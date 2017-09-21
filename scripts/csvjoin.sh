#!/bin/bash

if [ $# -lt 2 ]; then
  echo $0: Join two CSV files, using the header of the first.
  echo Output goes to stdout.
  echo ""
  echo Usage: $0 $file1 $file2
  exit 1
fi

FILE1=$1
FILE2=$2
shift
shift

if [[ ! -f $FILE1 ]]; then
  echo File $FILE1 not found.
  exit 1
fi

if [[ ! -f $FILE2 ]]; then
  echo File $FILE2 not found.
  exit 1
fi

cat $FILE1
tail +2 $FILE2
