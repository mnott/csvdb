#!/bin/bash

VIEWS=./views

OWNER=$1
shift

./csvdb.pl -v $VIEWS/owner.sql -p OWNER="$OWNER" $@
