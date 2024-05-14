#!/bin/bash

CONJUR_HOME=${CONJUR_HOME:-~/Conjur/cybrsm-demos} 

source $CONJUR_HOME/config/conjur.config
source ./bamboovars.sh

$DOCKER stop $BAMBOO_DEMO_CONTAINER
$DOCKER rm $BAMBOO_DEMO_CONTAINER
$DOCKER volume rm $BAMBOO_DEMO_VOLUME
