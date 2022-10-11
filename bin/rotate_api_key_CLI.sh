#!/bin/bash
if [[ $# != 1 ]];then
  echo "Usage: $0 <host-name>"
  exit -1
fi
docker exec -it conjur-cli \
  conjur host rotate_api_key -h $1
