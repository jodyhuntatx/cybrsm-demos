#!/bin/bash

# Starts external agent in separate container

CONJUR_HOME=${CONJUR_HOME:-~/Conjur/cybrsm-demos} 

source $CONJUR_HOME/config/conjur.config
source ./bamboovars.sh

main() {
  pushd build/agent
    ./build.sh
  popd
  start_bamboo_agent
}

########################################
start_bamboo_agent() {
    $DOCKER run -d 							\
      --hostname $BAMBOO_AGENT_CONTAINER				\
      --name $BAMBOO_AGENT_CONTAINER 					\
      --add-host "$CONJUR_LEADER_HOSTNAME:$CONJUR_LEADER_HOST_IP" 	\
      -e "JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64"			\
      -e "TERM=xterm" 							\
      --restart always 							\
      --entrypoint "sh" 						\
      $BAMBOO_AGENT_IMAGE						\
      -c "/root/bamboo-agent-home/bin/bamboo-agent.sh console" 
}

main "$@"
