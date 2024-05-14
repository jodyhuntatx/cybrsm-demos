#!/bin/bash 
########################################
##  This script executes on AWS host  ##
########################################

source ../demo.config

sudo apt-get update
sudo apt-get install -qy ruby-dev rubygems build-essential
# use -V argument for verbose gem install output
sudo gem install aws-sdk-core
sudo gem install aws-sigv4
sudo gem install conjur-api
