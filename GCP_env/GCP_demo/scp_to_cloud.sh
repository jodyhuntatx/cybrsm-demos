#!/bin/bash
source conjur_setup/gcp.config

CLOUD_DIRS="conjur_setup"
set -x
for i in $CLOUD_DIRS; do
  scp -r -i $GCP_SSH_KEY $i $LOGIN_USER@$GCP_PUB_IP:~/
done
