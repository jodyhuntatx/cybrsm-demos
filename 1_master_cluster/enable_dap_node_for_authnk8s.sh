#!/bin/bash
set -eou pipefail

source ../config/conjur.config
source ../config/dockerdesktop.k8s
source ../bin/conjur_utils.sh

# This script enables authn-k8s in a running Conjur node (Master or Follower) running in Docker.
# It's useful for enabling authn-k8s after standing the node up.
# It must be run on the host where the Conjur node is running.
# It does NOT need to use kubectl or oc.

#################
main() {
set -x
  configure_authn_k8s
set +x
  wait_till_node_is_responsive
  curl -k $CONJUR_LEADER_URL/info
  update_follower_cert
}

###################################
configure_authn_k8s() {
  echo "Initializing Conjur K8s authentication policies..."

  cp ./templates/master-seed-generation-policy.template.yaml ./policy/master-seed-generation-policy.yaml
  conjur_append_policy root ./policy/master-seed-generation-policy.yaml

  sed -e "s#{{ CLUSTER_AUTHN_ID }}#$CLUSTER_AUTHN_ID#g"                 \
        ./templates/master-authenticator-policy.template.yaml           \
  | sed -e "s#{{ CYBERARK_NAMESPACE_NAME }}#$CYBERARK_NAMESPACE_NAME#g" \
  > ./policy/master-authenticator-policy.yaml
  conjur_append_policy root ./policy/master-authenticator-policy.yaml delete

  if $REMOTE_CONJUR_LEADER; then
    interpreter="ssh -i $SSH_PVT_KEY $SSH_USERNAME@$CONJUR_LEADER_HOSTNAME"
  else
    interpreter=bash
  fi

#  $interpreter <<EOF

####################
# create CA

# create CONFIG environment variable
CONFIG="
[ req ]
distinguished_name = dn
x509_extensions = v3_ca
[ dn ]
[ v3_ca ]
basicConstraints = critical,CA:TRUE
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer:always
"
# generate the openssl private key
openssl genrsa -out ca.key 2048

# generate the root CA certificate
openssl req -x509 -new -nodes -key ca.key -sha1 -days 3650 -set_serial 0x0 -out ca.cert \
  -subj "/CN=conjur.authn-k8s.$CLUSTER_AUTHN_ID/OU=Conjur Kubernetes CA/O=$CONJUR_ACCOUNT" \
  -config <(echo "$CONFIG")

# verify certificate
#openssl x509 -in ca.cert -text -noout

$DOCKER exec $CLI_CONTAINER_NAME		\
	conjur variable values add conjur/authn-k8s/$CLUSTER_AUTHN_ID/ca/key "$(cat ca.key)"
$DOCKER exec $CLI_CONTAINER_NAME 		\
	conjur variable values add conjur/authn-k8s/$CLUSTER_AUTHN_ID/ca/cert "$(cat ca.cert)"

#EOF

  # authn-jwt pre-enabled via conjur.yml file in leader

rm ca.cert ca.key

}

############################
wait_till_node_is_responsive() {
  set +e
  node_is_healthy=""
  while [[ "$node_is_healthy" == "" ]]; do
    sleep 2
    node_is_healthy=$(curl -sk $CONJUR_LEADER_URL/health | grep "ok" | tail -1 | grep "true")
  done
  set -e
}

############################
update_follower_cert() {

  rm -f $FOLLOWER_CERT_FILE
  $DOCKER exec $CONJUR_LEADER_CONTAINER_NAME \
        bash -c "evoke ca issue -f conjur-follower $CONJUR_FOLLOWER_SERVICE_NAME"
  $DOCKER cp -L $CONJUR_LEADER_CONTAINER_NAME:/opt/conjur/etc/ssl/conjur-follower.pem $FOLLOWER_CERT_FILE
}

main "$@"
