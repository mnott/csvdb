#!/bin/bash
#
# Sort a product list and throw away dupes (easy approach)

export FILE=$1

head -1 $FILE >$FILE.hdr

tail +2 $FILE | perl -pe "s/\t(.*)/,\"\1\"/g" | sort | uniq >>$FILE.hdr


mv $FILE.hdr $FILE

