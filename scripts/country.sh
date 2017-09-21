#!/bin/bash

#
# Default Dataset
#
if [[ $DATASET == "" ]]; then
  export DATASET=current
fi

#
# Check whether we have at least one command line parameter
#
if [[ $# == 0 ]]; then
  echo "Usage: [DATATASET=current] $0 country"
  exit 1
fi

#
# Get the country
#
COUNTRY=$1
shift

./csvdb.pl -dir ./data/$DATASET/data -v ./data/$DATASET/views/country.sql -p COUNTRY="$COUNTRY" $@
