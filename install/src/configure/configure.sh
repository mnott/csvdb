#!/bin/bash

if [ -f configure_always.sh ]; then
	./configure_always.sh;
fi

status=/var/log/status

if [ ! -d $status ]; then
	mkdir $status;
fi

run () {
	if [ -f $status/$1_done ]; then
		echo $1 already done;
		return;
	fi

	pwd
	eval ./$1.sh
	touch $status/$1_done
}


#
# Put the commands to configure here
#
run configure_system
run configure_apache
run configure_perl



