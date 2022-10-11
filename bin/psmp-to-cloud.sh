#!/bin/bash

export CONJUR_HOME=~/Conjur/conjur-demo-env

case $1 in
  aws)
	source $CONJUR_HOME/config/aws.config
	SSH_USER=ubuntu
	PUB_DNS=$AWS_PUB_DNS
	;;
  azure)
	source $CONJUR_HOME/config/azure.config
	SSH_USER=ocuser
	PUB_DNS=$AZURE_PUB_DNS
	;;
  *)
	echo "Usage: $0 < aws | azure >"
	exit -1
	;;
esac
set -x
ssh Administrator@$SSH_USER@$PUB_DNS@psmphost
