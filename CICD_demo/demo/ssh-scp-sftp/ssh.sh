#!/bin/bash
if [[ $# != 2 ]]; then
  echo "Usage: $0 [ test | prod ] <command>"
  exit -1
fi
export ENV=$1
export COMMAND=$2
summon -e $ENV bash -c "set -x; ssh -i \$SSH_KEY \$USER_NAME@\$HOST_NAME \$COMMAND"
