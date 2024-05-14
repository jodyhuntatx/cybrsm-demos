#!/bin/bash

CONJUR_HOME=${CONJUR_HOME:-~/Conjur/cybrsm-demos} 

source $CONJUR_HOME/config/conjur.config
source ./bamboovars.sh

main() {
  pushd build/server
    ./build.sh
  popd
#  start_bamboo
  gen_bamboo_host_id
  display_config_info
}

########################################
start_bamboo() {
  	# create volume for persistence of state across container instances
  if [[ "$($DOCKER volume ls | grep $BAMBOO_DEMO_VOLUME)" == "" ]]; then
    $DOCKER volume create $BAMBOO_DEMO_VOLUME 
  fi

  if [[ "$($DOCKER ps | grep $BAMBOO_DEMO_CONTAINER)" == "" ]]; then
    $DOCKER run -d 							\
      --hostname $BAMBOO_DEMO_CONTAINER					\
      --name $BAMBOO_DEMO_CONTAINER 					\
      -e "BAMBOO_HOME=$BAMBOO_HOME"					\
      -e "JAVA_HOME=$JAVA_HOME"						\
      -e "TERM=xterm" 							\
      -p "$BAMBOO_PORT:8085"						\
      -v "$BAMBOO_DEMO_VOLUME:$BAMBOO_HOME" 				\
      --restart always 							\
      --entrypoint "sh" 						\
      --shm-size $BAMBOO_SHM_SIZE					\
      $BAMBOO_DEMO_IMAGE						\
      -c "sleep infinity"
  fi

  $DOCKER cp $CONJUR_CERT_FILE $BAMBOO_DEMO_CONTAINER:/conjur-cert.pem

  echo
  echo
  echo "Keystore Password is: changeit"
  echo
  echo

  $DOCKER exec -itu root $BAMBOO_DEMO_CONTAINER      \
        keytool -importcert -alias conjur -keystore $KEYSTORE -file /conjur-cert.pem

  $DOCKER exec $BAMBOO_DEMO_CONTAINER      \
	bash -c "/opt/bamboo/current/bin/start-bamboo.sh start"
}

########################################
gen_bamboo_host_id() {
  echo \
"- !host $BAMBOO_HOST_ID
- !grant
  role: !group $VAULT_NAME/$LOB_NAME/$SAFE_NAME/delegation/consumers
  member: !host $BAMBOO_HOST_ID"	\
  > tmp
  cybr conjur logon-non-interactive
  cybr conjur append-policy -b root -f tmp
  rm tmp
  bot_api_key=$(cybr conjur rotate-api-key -l host/$BAMBOO_HOST_ID)
}

########################################
display_config_info() {
  echo "Waiting for Bamboo to start up..."
  sleep 15
  clear
  echo
  echo "======== Configuration info ========="
  echo
  echo "Bamboo URL: http://$BAMBOO_PUB_DNS:$BAMBOO_PORT"
  echo
  echo "Conjur plugin config values:"
  echo "  Account: $CONJUR_ACCOUNT"
  echo "  Appliance URL: $CONJUR_APPLIANCE_URL"
  echo "  Plugin host ID: $BAMBOO_HOST_ID"
  echo "  Plugin API key: $bot_api_key"
  echo
  echo
  echo
}

main "$@"
