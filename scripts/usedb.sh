#!/bin/bash

if [[ $# < 1 ]]; then
	echo Usage: $0 old
	exit 1
fi

for i in $(find data/input/ -type d -depth 1); do (cd $i/data/ && rm -f hcp.csv && cp -av hcp_$1.csv hcp.csv); done
for i in $(find data/input/ -type d -depth 1); do ls -la $i/data/hcp.csv; done
