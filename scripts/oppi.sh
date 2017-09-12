#!/bin/bash

VIEWS=./views

OPPI=$1
shift

./csvdb.pl -v $VIEWS/oppi.sql -p OPPI="$OPPI" $@
