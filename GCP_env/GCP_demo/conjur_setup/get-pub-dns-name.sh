#!/bin/bash

source ./gcp.config

IP1=$(echo $GCP_PUB_IP | cut -d . -f 1)
IP2=$(echo $GCP_PUB_IP | cut -d . -f 2)
IP3=$(echo $GCP_PUB_IP | cut -d . -f 3)
IP4=$(echo $GCP_PUB_IP | cut -d . -f 4)
DNS_NAME="$IP4.$IP3.$IP2.$IP1.bc.googleusercontent.com"
echo $DNS_NAME
