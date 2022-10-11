#!/bin/bash

# Brings up and configures a Follower using unencrypted keys. 
# This script will fail if Master keys are encrypted.

source ./keymgmt.config

./stop

# Generate seed file from master keys
$DOCKER exec -i $CONJUR_MASTER_CONTAINER_NAME \
	evoke seed follower $CONJUR_MASTER_HOST_NAME > $FOLLOWER_SEED_FILE

# Bring up Conjur Follower node
$DOCKER run -d \
    --name $CONJUR_FOLLOWER_CONTAINER_NAME \
    --label role=conjur_node \
    -p "$CONJUR_FOLLOWER_PORT:443" \
    -e "CONJUR_AUTHENTICATORS=$CONJUR_AUTHENTICATORS" \
    --restart always \
    --security-opt seccomp:unconfined \
    $CONJUR_APPLIANCE_IMAGE

# add entry to follower's /etc/hosts so $CONJUR_MASTER_HOST_NAME resolves
$DOCKER exec -it $CONJUR_FOLLOWER_CONTAINER_NAME \
        bash -c "echo \"$CONJUR_MASTER_HOST_IP $CONJUR_MASTER_HOST_NAME\" >> /etc/hosts"

echo "Initializing Conjur Follower"
$DOCKER cp $FOLLOWER_SEED_FILE \
                $CONJUR_FOLLOWER_CONTAINER_NAME:/tmp/follower-seed.tar
$DOCKER exec $CONJUR_FOLLOWER_CONTAINER_NAME \
                evoke unpack seed /tmp/follower-seed.tar
$DOCKER exec $CONJUR_FOLLOWER_CONTAINER_NAME \
                evoke configure follower -p $CONJUR_MASTER_PORT

echo "Follower configured."
