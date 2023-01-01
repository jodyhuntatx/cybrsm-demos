#!/bin/bash

CONJUR_HOME=${CONJUR_HOME:-~/Conjur/cybrsm-demos} 

source $CONJUR_HOME/config/conjur.config
source ./bamboovars.sh

echo
echo "Deletes running container while retaining container state."
echo
echo "Press <return> to continue, <Ctrl-C> to exit..."
read foo
echo "Stopping container..."
$DOCKER stop $BAMBOO_DEMO_CONTAINER
echo "Removing container..."
$DOCKER rm $BAMBOO_DEMO_CONTAINER
echo
echo "To restart with current state, run: 0-start-server.sh"
echo
