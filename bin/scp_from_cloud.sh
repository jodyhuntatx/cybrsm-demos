#!/bin/bash

# Copies remote cloud VM directories to local counterparts

# directories to copy from cloud host
CONJUR_CLUSTER_SETUP_DIRS="1_master_cluster bin config"

export CONJUR_HOME=~/Conjur/conjur-demo-env

case $1 in
  aws)
	source $CONJUR_HOME/config/aws.config
	SSH_KEY=$AWS_SSH_KEY
	PUB_DNS=$AWS_PUB_DNS
        CLOUD_DIRS="$CONJUR_CLUSTER_SETUP_DIRS AWS_demo"
	;;
  azure)
	source $CONJUR_HOME/config/azure.config
	SSH_KEY=$AZURE_SSH_KEY
	PUB_DNS=$AZURE_PUB_DNS
        CLOUD_DIRS="$CONJUR_CLUSTER_SETUP_DIRS"
	;;
  *)
	echo "Usage: $0 < aws | azure >"
	exit -1
	;;
esac

set -x
for i in $CLOUD_DIRS; do
  scp -r -i $SSH_KEY $LOGIN_USER@$PUB_DNS:~/$i $i 
done
