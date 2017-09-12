#!/bin/bash

VIEWS=./views

CUSTOMER=$1
shift

./csvdb.pl -v $VIEWS/customer.sql -p CUSTOMER="$CUSTOMER" $@
