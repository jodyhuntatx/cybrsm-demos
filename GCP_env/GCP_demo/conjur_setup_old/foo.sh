#!/bin/bash

IP=35.194.44.78

IP1=$(echo $IP | cut -d . -f 1)
IP2=$(echo $IP | cut -d . -f 2)
IP3=$(echo $IP | cut -d . -f 3)
IP4=$(echo $IP | cut -d . -f 4)
DNS_NAME="$IP4.$IP3.$IP2.$IP1.bc.googleusercontent.com"
ping $DNS_NAME
