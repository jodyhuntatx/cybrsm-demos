#!/bin/bash
export CONJUR_HOME=~/Conjur/cybrsm-demos

echo "Current IP address: $(curl -sk https://checkip.amazonaws.com)"

case $1 in
  aws)
	source $CONJUR_HOME/config/aws.config
	SSH_KEY=$AWS_SSH_KEY
	PUB_DNS=$AWS_PUB_DNS
	;;
  azure)
	source $CONJUR_HOME/config/azure.config
	SSH_KEY=$AZURE_SSH_KEY
	PUB_DNS=$AZURE_PUB_DNS
	;;
  *)
	echo "Usage: $0 < aws | azure >"
	exit -1
	;;
esac

ssh -i $SSH_KEY $LOGIN_USER@$PUB_DNS
