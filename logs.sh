#!/bin/bash

if test $# -ne 2; then
	echo error: missing args
	exit 1
fi

aws logs filter-log-events --log-group-name $1 --profile $2 | jq '.events[].message'
