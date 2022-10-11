#!/bin/bash
set -eou pipefail

source ./gcp.config

cat policy/authn-gcp.yml | $DOCKER exec -i conjur-cli conjur policy load root -
$DOCKER exec $CONJUR_LEADER_CONTAINER_NAME bash -c "grep -qxF 'authenticators:' /etc/conjur/config/conjur.yml || echo 'authenticators:' >> /etc/conjur/config/conjur.yml"
$DOCKER exec $CONJUR_LEADER_CONTAINER_NAME bash -c "grep -qxF 'authn-gcp:' /etc/conjur/config/conjur.yml || echo '  - authn-gcp' >> /etc/conjur/config/conjur.yml"
$DOCKER exec $CONJUR_LEADER_CONTAINER_NAME evoke configuration apply
