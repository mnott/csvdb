#!/bin/bash

#
# Default Dataset
#
if [[ $DATASET == "" ]]; then
  export DATASET=cloud_consolidated_pipeline
fi

#
# Get the country
#
COUNTRY=$1
shift

./csvdb.pl -dir ./data/$DATASET/data -v ./data/$DATASET/views/countries.sql $@
