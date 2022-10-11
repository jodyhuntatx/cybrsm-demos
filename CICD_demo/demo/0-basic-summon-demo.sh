#!/bin/bash
if [[ "$1" == "" ]]; then
	echo "need to specify an environment (dev, test or prod)"
	exit 01
fi
summon -e $1 ./secrets_echo.sh
