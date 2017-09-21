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
  echo "Usage: [DATATASET=current] $0 product"
  exit 1
fi

#
# Get the product
#
PRODUCT=$1
shift

./csvdb.pl -dir ./data/$DATASET/data -v ./data/$DATASET/views/product.sql -p PRODUCT="$PRODUCT" $@
