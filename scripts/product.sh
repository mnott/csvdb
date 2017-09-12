#!/bin/bash

VIEWS=./views

PRODUCT=$1
shift

./csvdb.pl -v $VIEWS/product.sql -p PRODUCT="$PRODUCT" $@
