#!/bin/bash
if [[ $# != 2 ]]; then
  echo "Usage $0 <resource> <permission>"
  exit -1
fi
docker exec conjur-cli conjur resource permitted_roles $1 $2
