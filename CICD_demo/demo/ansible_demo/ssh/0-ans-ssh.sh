#!/bin/bash
if [[ $# != 1 ]]; then
  echo "Usage: $0 [ test | prod ]"
  exit -1
fi
export ENV=$1
export ANSIBLE_MODULE=ping
set -x
summon -e $ENV bash -c "ansible -m $ANSIBLE_MODULE -i ./ansible_hosts $ENV --private-key=\$SSH_KEY -u \$USER_NAME"
