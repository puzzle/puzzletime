#!/bin/bash

if [ ! -n "$2" ]
then
	echo "Usage: $0 [user] [password]"
	exit 1
fi

wget --post-data 'user='$1'&pwd='$2 -q -O - https://secure.worldweb2000.com/puzzletime/attendancetime/autoStartStop
