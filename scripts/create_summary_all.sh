#!/bin/bash

#
# Timestamp
#
export TS=`date +"%Y-%m-%d"`


for i in la na gc apj mee emean emeas; do scripts/create_summary_region.sh $i $TS rep_recoding_candidates "Recoding Candidates"; done
for i in la na gc apj mee emean emeas; do scripts/create_summary_region.sh $i $TS rep_pipeline "Pipeline Review"; done

