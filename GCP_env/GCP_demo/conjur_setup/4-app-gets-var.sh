#!/bin/bash
source ./gcp.config

export CONJUR_HOST_ID=gcp-demo/gcp-client
VAR_VALUE=$(./summon-conjur-gcp.sh secrets/db-password)
echo $VAR_VALUE
