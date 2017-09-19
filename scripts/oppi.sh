#!/bin/bash

#
# Default Dataset
#
if [[ $DATASET == "" ]]; then
  export DATASET=cloud_consolidated_pipeline
fi

#
# Check whether we have at least one command line parameter
#
if [[ $# == 0 ]]; then
  echo "Usage: [DATATASET=cloud_consolidated_pipeline] $0 oppi"
  exit 1
fi

#
# Get the country
#
OPPI=$1
shift

./csvdb.pl -dir ./data/$DATASET/data -v ./data/$DATASET/views/oppi.sql -p OPPI="$OPPI" $@
