#!/bin/bash
if [[ $# != 3 ]]; then
  echo "Usage: $0 [ test | prod ] <local-path> <remote-path>"
  exit -1
fi
export ENV=$1
export LOCAL_PATH=$2
export REMOTE_PATH=$3
summon -e $ENV bash -c "set -x; scp -i \$SSH_KEY \$LOCAL_PATH \$USER_NAME@\$HOST_NAME:\~\$USER_NAME/\$REMOTE_PATH"
