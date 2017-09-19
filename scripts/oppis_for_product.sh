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
  echo "Usage: [DATATASET=cloud_consolidated_pipeline] $0 product"
  exit 1
fi

#
# Get the product
#
PRODUCT=$1
shift

./csvdb.pl -dir ./data/$DATASET/data -s "select bp_org_name, opportunity_id, tcv_keur, opportunity_description, product, product_desc from pipeline where product = $PRODUCT order by bp_org_name, opportunity_id" $@
