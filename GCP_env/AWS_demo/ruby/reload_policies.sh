#!/bin/bash 
########################################
##  This script executes on AWS host  ##
########################################

source ./demo.config

if [[ "$(cat /etc/os-release | grep 'Ubuntu 18')" == "" ]]; then
  echo "These installation scripts assume Ubuntu 18"
  exit -1
fi

if [[ "$CONJUR_MASTER_HOST_NAME" == "" ]]; then
  echo "Please edit demo.config and set CONJUR_MASTER_HOST_NAME to the Public DNS hostname of the Conjur Master."
  exit -1
fi

./load_policy_REST.sh root policy/identities.yaml
./load_policy_REST.sh root policy/secrets.yaml
./var_value_add_REST.sh database/username OracleDBuser
./var_value_add_REST.sh database/password ueus#!9
./load_policy_REST.sh root policy/access-grants.yaml
