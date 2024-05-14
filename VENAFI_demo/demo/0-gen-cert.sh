#!/bin/bash -x
if [[ $# != 1 ]]; then
  echo "Usage: $0 <app-name>"
  exit -1
fi
APP_NAME=$1
vcert enroll --cn $APP_NAME -z $APP_NAME\\Default
