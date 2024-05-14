#!/bin/bash
if [[ $# != 1 ]]; then
  echo "Provide dev, test or prod to specify environment."
  exit -1
fi
clear
set -x
summon -e $1 chef-solo -c $PWD/solo.rb -o chef-summon::secrets-echo
