#!/bin/bash
source ./demo.config
source ./bin/conjur_utils.sh

export CONJUR_AUTHN_LOGIN=admin
export CONJUR_AUTHN_API_KEY=$CONJUR_ADMIN_PASSWORD

# Install Summon & Summon-conjur provider
# Loads demo policy
# Configures/enables authn-iam

#################
main() {
  install_summon
  load_policies
  set_variable_values
  sudo docker exec $CONJUR_LEADER_CONTAINER_NAME \
	  evoke variable set CONJUR_AUTHENTICATORS authn,authn-iam/$AUTHN_IAM_SERVICE_ID
  sleep 5
  curl -k $CONJUR_APPLIANCE_URL/info
}

load_policies() {
  conjur_append_policy root policy/authn-iam.yaml
  conjur_append_policy root policy/identities.yaml
  conjur_append_policy root policy/secrets.yaml
  conjur_append_policy root policy/access-grants.yaml
}

#################
install_summon() {
  curl -sSL https://raw.githubusercontent.com/cyberark/summon/master/install.sh    \
  | env TMPDIR=$(mktemp -d) sudo bash                                                   \
  && curl -sSL https://raw.githubusercontent.com/cyberark/summon-conjur/master/install.sh     \
  | env TMPDIR=$(mktemp -d) sudo bash
}

set_variable_values() {
  conjur_set_variable database/username OracleDBuser
  conjur_set_variable database/password ueus#!9
}

main "$@"
