#!/bin/bash

VIEWS=./views

COUNTRY=$1
shift

./csvdb.pl -v $VIEWS/country.sql -p COUNTRY="$COUNTRY" $@
