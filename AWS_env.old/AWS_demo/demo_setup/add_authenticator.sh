#!/bin/bash

source ../demo.config
source ../bin/conjur_utils

# This script deletes running instances and brings up 
#   initialized Conjur Master, Follower & CLI nodes.
#   It also setups the Summon AWS secrets provider.

#################
main() {
  enable_iam_authn $CONJUR_MASTER_CONTAINER_NAME
}

#################
enable_iam_authn() {
  local container_name=$1; shift
  load_policy_REST.sh root policy/authn-iam.yaml
  sudo docker exec $container_name \
	  evoke variable set CONJUR_AUTHENTICATORS authn,authn-iam/$AUTHN_IAM_SERVICE_ID
}

main "$@"
