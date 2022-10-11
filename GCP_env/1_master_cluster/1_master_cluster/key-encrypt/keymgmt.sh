#!/bin/bash

source ./keymgmt.config

###########################################################################
# After initial encryption of the server keys with "evoke keys encrypt",
# subsequent evoke configuration commands require use of this syntax:
#
#   evoke keys exec -m <master-key-file | -> -- <evoke-command>
#
# Affected commands:
#  - evoke configure (except on creation of the initial Master)
#  - evoke unpack
#  - evoke restore --accept-eula
#
# CA commands require that all keys are first decrypted:
#   evoke keys decrypt-all <master-key-file | ->
#
# Affected commands:
#  - evoke ca issue
#  - evoke ca regenerate
###########################################################################

main() {
  if [[ $# != 2 ]]; then
    echo "Usage: $0 [ init | enc | dec | lock | unlock | list | health | ca ] <conjur-appliance-container-name>"
    exit -1
  fi
  CMD=$1
  CNAME=$2

  case $CMD in
    init )
	initial-encrypt $CNAME
	list-keys $CNAME
	;;

    enc )
	encrypt-all-server-keys $CNAME
	unlock-node $CNAME
	restart-services $CNAME
	sleep 10
	check-health $CNAME
	list-keys $CNAME
	;;

    dec )
	decrypt-all-server-keys $CNAME
	list-keys $CNAME
	;;

    lock )
	lock-node $CNAME
	list-keys $CNAME
	;;

    unlock )
	unlock-node $CNAME
	restart-services $CNAME
	echo "Waiting for services to start..."
	sleep 10
	check-health $CNAME
	list-keys $CNAME
	;;

    list )
	list-keys $CNAME
	;;

    health )
	check-health $CNAME
	;;

    ca )
	ca-issue $CNAME
	list-keys $CNAME
	;;

    * )
	echo "Unknown command."
	;;

  esac

}

#########################
# Performs initial key encryption on Master node, creating MASTER_KEY_FILE.
initial-encrypt() {
  local cname=$1; shift

  if [[ "$($DOCKER exec $cname evoke role)" != "master" ]]; then
    echo "Initial key encryption only works on the Master node. Exiting..."
    exit -1
  elif [[ -f "$MASTER_KEY_FILE" ]]; then
    echo "Master key file exists. Decrypt all keys on all nodes and delete master key file before running."
    exit -1
  fi

  lock-node $cname
  gen-new-master-key $cname
  encrypt-all-server-keys $cname
  unlock-node $cname
  restart-services $cname
  echo "Waiting for services to start..."
  sleep 10
  check-health $cname
}

#########################
# lock-node - stop pg, conjur & nginx services, remove keys from keyring
lock-node() {
  local cname=$1; shift
  $DOCKER exec $cname evoke keys lock
}

#########################
gen-new-master-key() {
  local cname=$1; shift
  $DOCKER exec $cname openssl rand 32 > $MASTER_KEY_FILE
}

#########################
encrypt-all-server-keys() {
  local cname=$1; shift
  cat $MASTER_KEY_FILE | $DOCKER exec -i $cname evoke keys encrypt -
}

#########################
decrypt-all-server-keys() {
  local cname=$1; shift
  $DOCKER exec $cname rm -f /opt/conjur/etc/ui.key	# ui.key is not moved to the keyring
  cat $MASTER_KEY_FILE | $DOCKER exec -i $cname evoke keys decrypt-all -
}

#########################
# Decrypt server keys and push to container keyring
unlock-node() {
  local cname=$1; shift
  cat $MASTER_KEY_FILE | $DOCKER exec -i $cname evoke keys unlock -
}

#########################
# Restart DB, Conjur and NGINX services after unlocking keys
restart-services() {
  local cname=$1; shift
  $DOCKER exec $cname bash -c "sv restart pg && sv restart conjur && sv restart nginx"
}

#########################
# Issue Follower cert with additional SANs to those used in FOLLOWER_ALT_NAMES for Master
ca-issue() {
  local cname=$1; shift

  if [[ "$($DOCKER exec $cname evoke role)" != "master" ]]; then
    echo "CA services only work on the Master node. Exiting..."
    exit -1
  fi
  decrypt-all-server-keys $cname
  $DOCKER exec $cname evoke ca issue --force foo-bar
  $DOCKER cp $cname:/opt/conjur/etc/ssl/foo-bar.pem .
  encrypt-all-server-keys $cname
}

#########################
check-health() {
  local cname=$1; shift
  $DOCKER exec $cname curl -sk localhost/health
}

#########################
list-keys() {
  local cname=$1; shift
  echo
  echo
  echo "Keys in /opt/conjur/etc:"
  $DOCKER exec $cname bash -c "ls -l /opt/conjur/etc | grep key"
  echo
  echo "Keys in /opt/conjur/etc/ssl:"
  $DOCKER exec $cname bash -c "ls -l /opt/conjur/etc/ssl | grep key"
}

main "$@"
