#!/bin/bash
if [[ $# != 2 ]]; then
  echo "Usage: $0 [ test | prod ] <remote-path>"
  exit -1
fi
export ENV=$1
export LOCAL_PATH=$2
export REMOTE_PATH=$3
summon -e $ENV bash -c "set -x; sftp -i \$SSH_KEY \$USER_NAME@\$HOST_NAME:\$REMOTE_PATH"
