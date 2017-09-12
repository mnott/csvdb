#!/bin/bash

VIEWS=./views

if [ $# -lt 2 ]; then
  echo Usage: $0 outputfile oppid
  exit 1
fi

FILE=$1
OPPI=$2
shift
shift

if [[ ! -f $FILE ]]; then
  ./csvdb.pl -v $VIEWS/oppi.sql -p OPPI="$OPPI" -r | head -2 | tee $FILE
else
  ./csvdb.pl -v $VIEWS/oppi.sql -p OPPI="$OPPI" -r -h | head -1 | tee -a $FILE
fi
