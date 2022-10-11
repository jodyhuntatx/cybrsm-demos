#!/bin/bash 
########################################
##  This script executes on AWS host  ##
########################################

source ../demo.config

if [[ "$(cat /etc/os-release | grep 'Ubuntu 18')" == "" ]]; then
  echo "These installation scripts assume Ubuntu 18"
  exit -1
fi

if [[ "$CONJUR_MASTER_HOST_NAME" == "" ]]; then
  echo "Please edit demo.config and set CONJUR_MASTER_HOST_NAME to the Public DNS hostname of the Conjur Master."
  exit -1
fi

main() {
  load_policies
exit
  ruby_setup
  install_summon
  install_jq
  load_policies
}

ruby_setup() {
  sudo apt-get update
  sudo apt-get install -qy ruby-dev rubygems build-essential
  # use -V argument for verbose gem install output
  sudo gem install aws-sdk-core
  sudo gem install aws-sigv4
  sudo gem install conjur-api
}

install_summon() {
  ###
  # Also install Summon and create directory for providers
  pushd /tmp
  curl -LO https://github.com/cyberark/summon/releases/download/v0.6.7/summon-linux-amd64.tar.gz \
    && tar xzf summon-linux-amd64.tar.gz \
    && sudo mv summon /usr/local/bin/ \
    && rm summon-linux-amd64.tar.gz
  popd
}

install_jq() {
  sudo snap install jq
}

load_policies() {
   export AUTHN_USERNAME=admin
   export AUTHN_PASSWORD=$(keyring get conjur adminpwd)

  load_policy_REST.sh root policy/identities.yaml
  load_policy_REST.sh root policy/secrets.yaml
  var_value_add_REST.sh database/username OracleDBuser
  var_value_add_REST.sh database/password ueus#!9
  load_policy_REST.sh root policy/access-grants.yaml
}

main "$@"
