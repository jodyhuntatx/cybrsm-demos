#!/bin/bash
source conjur_setup/azure.config

CLOUD_DIRS="tf_demo conjur_setup conjur-etc"
set -x
for i in $CLOUD_DIRS; do
  scp -r -i $AZURE_SSH_KEY $LOGIN_USER@$AZURE_PUB_DNS:~/$i .
done
