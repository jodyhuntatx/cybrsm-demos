#!/bin/bash

CONJUR_HOME=${CONJUR_HOME:-~/Conjur/cybrsm-demos} 

source $CONJUR_HOME/config/conjur.config
source ./bamboovars.sh

main() {
  pushd build/server
    ./build.sh
  popd
  start_bamboo
}

########################################
start_bamboo() {
  $DOCKER run -d 							\
      --hostname $BAMBOO_DEMO_CONTAINER					\
      --name $BAMBOO_DEMO_CONTAINER 					\
      -e "CONJUR_LEADER_HOSTNAME=$CONJUR_CORE_URL"			\
      -e "CONJUR_ACCOUNT=$CONJUR_ACCOUNT"				\
      -e "CONJUR_APPLIANCE_URL=$CONJUR_APPLIANCE_URL"			\
      -e "CONJUR_AUTHN_LOGIN=admin"					\
      -e "CONJUR_AUTHN_API_KEY=$CONJUR_AUTHN_API_KEY"			\
      -e "CONJUR_CERT_FILE=/conjur-cert.pem"				\
      -e "BAMBOO_HOME=/home/bamboo"					\
      -e "JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64"			\
      -e "TERM=xterm" 							\
      -p "$BAMBOO_PORT:8085"						\
      --restart always 							\
      --entrypoint "sh" 						\
      $BAMBOO_DEMO_IMAGE						\
      -c "sleep infinity"


  $DOCKER cp $CONJUR_CERT_FILE $BAMBOO_DEMO_CONTAINER:/conjur-cert.pem

  $DOCKER exec -itu root $BAMBOO_DEMO_CONTAINER      \
        keytool -importcert -alias conjur -keystore $KEYSTORE -file /conjur-cert.pem

  $DOCKER exec $BAMBOO_DEMO_CONTAINER      \
	bash -c "/opt/bamboo/current/bin/start-bamboo.sh start"

  echo "- !host bamboo_bot" > tmp
  cybr conjur append-policy -b root -f tmp
  bot_api_key=$(cybr conjur rotate-api-key -l host/bamboo_bot)

  echo "Waiting for Bamboo to start up..."
  sleep 15
  echo
  echo
  echo
  echo
  echo "======== Configuration info ========="
  echo
  echo "Bamboo URL: http://$BAMBOO_PUB_DNS:$BAMBOO_PORT"
  echo
  echo
  echo "Conjur plugin config values:"
  echo "  Account: $CONJUR_ACCOUNT"
  echo "  Appliance URL: $CONJUR_APPLIANCE_URL"
  echo "  Plugin host ID: bamboo_bot"
  echo "  Plugin API key: $bot_api_key"
  echo
  echo
  echo
}

main "$@"
