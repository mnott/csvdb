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
# Get the oppi
#
OPPI=$1
shift

./csvdb.pl -dir ./data/$DATASET/data -s "select bp_org_name, opportunity_id, tcv_keur, opportunity_description, product, product_desc from pipeline where opportunity_id = $OPPI order by bp_org_name, product_desc" $@
