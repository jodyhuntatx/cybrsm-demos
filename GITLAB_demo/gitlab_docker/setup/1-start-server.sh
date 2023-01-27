#!/bin/bash

# Doc page: https://docs.gitlab.com/ee/install/docker.html

CONJUR_HOME=${CONJUR_HOME:-~/Conjur/cybrsm-demos} 

source $CONJUR_HOME/config/conjur.config
source ../gitlabvars.sh

main() {
  start_container
  configure_gitlab
  generate_ssl_certs
  reconfigure_gitlab
  display_config_info
}

########################################
start_container() {
        # create volume for persistence of state across container instances
  if [[ "$($DOCKER volume ls | grep $GITLAB_CONFIG_VOLUME)" == "" ]]; then
    $DOCKER volume create $GITLAB_CONFIG_VOLUME
    $DOCKER volume create $GITLAB_LOGS_VOLUME
    $DOCKER volume create $GITLAB_DATA_VOLUME
  fi

  if [[ "$($DOCKER ps | grep $GITLAB_SERVER_CONTAINER)" == "" ]]; then
    $DOCKER run --detach 					\
      --hostname gitlab						\
      --publish $GITLAB_HTTPS_PORT:443				\
      --publish $GITLAB_HTTP_PORT:80				\
      --publish $GITLAB_SSH_PORT:22 				\
      --name $GITLAB_SERVER_CONTAINER				\
      --restart always 						\
      --mount src=$GITLAB_CONFIG_VOLUME,dst=/etc/gitlab  	\
      --mount src=$GITLAB_LOGS_VOLUME,dst=/var/log/gitlab  	\
      --mount src=$GITLAB_DATA_VOLUME,dst=/var/opt/gitlab  	\
      --shm-size $GITLAB_SHM_SIZE				\
      $GITLAB_SERVER_IMAGE
  fi
}

########################################
# post-startup configuration stuff
configure_gitlab() {
  echo
  echo
  echo
  echo "Monitor logs until configuration is complete."
  read -rsp $'Press any key to start monitoring logs. Use Ctrl-C to exit log streaming...\n' -n1 key
  $DOCKER logs -f $GITLAB_SERVER_CONTAINER --since 5m

  # stop redis from filling up disk with RDB snapshots
  $DOCKER exec $GITLAB_SERVER_CONTAINER \
	redis-cli -s /var/opt/gitlab/redis/redis.socket config set stop-writes-on-bgsave-error no
}

########################################
generate_ssl_certs() {
		# create ssl directory if it does not exist
   $DOCKER exec $GITLAB_SERVER_CONTAINER \
     mkdir -p /etc/gitlab/ssl
		# clear it out if it does exist
   $DOCKER exec $GITLAB_SERVER_CONTAINER \
     bash -c 'rm /etc/gitlab/ssl/*'

   $DOCKER exec $GITLAB_SERVER_CONTAINER 					\
	openssl genrsa -out '/etc/gitlab/ssl/gitlab.key' 2048

		# the runners want the hostname as a SAN, not just as the CN
   cat ./templates/gitlab_cert.cnf 						\
   | sed -e "s#{{ GITLAB_HOST_NAME }}#$GITLAB_HOST_NAME#"			\
   | sed -e "s#{{ GITLAB_SERVER_CONTAINER }}#$GITLAB_SERVER_CONTAINER#"		\
   | $DOCKER exec -i $GITLAB_SERVER_CONTAINER 					\
	openssl req -x509 -new -nodes -days 365 -sha256				\
		-config /dev/stdin						\
		-extensions v3_req						\
		-key '/etc/gitlab/ssl/gitlab.key'				\
		-out '/etc/gitlab/ssl/gitlab.pem'
}

########################################
reconfigure_gitlab() {
   		# update config file for https
		# see: https://blog.programster.org/dockerized-gitlab-configure-ssl
   cat ./templates/gitlab.rb 							\
   | sed -e "s#{{ GITLAB_HOST_NAME }}#$GITLAB_HOST_NAME#"			\
   | sed -e "s#{{ GITLAB_HTTPS_PORT }}#$GITLAB_HTTPS_PORT#"			\
   > gitlab.rb
   $DOCKER cp gitlab.rb $GITLAB_SERVER_CONTAINER:/etc/gitlab/
   rm gitlab.rb

   echo "Reconfiguring for HTTPS, this takes a couple of minutes..."
   $DOCKER exec $GITLAB_SERVER_CONTAINER 					\
     gitlab-ctl reconfigure
   $DOCKER exec $GITLAB_SERVER_CONTAINER 					\
     gitlab-ctl restart

   echo
   echo
   echo "Waiting one minute for GitLab to become responsive..."
   sleep 60
}

########################################
display_config_info() {
  echo
  echo
  echo
  echo
  echo "======== Configuration info ========="
  echo
  echo "GitLab URL: http://$GITLAB_HOST_NAME:$GITLAB_HTTPS_PORT"
  echo
  init_root_pwd=$($DOCKER exec -it $GITLAB_SERVER_CONTAINER grep Password: /etc/gitlab/initial_root_password | awk '{print $2}')
  echo "Admin login: root"
  echo "Admin password: $init_root_pwd"
  echo
  echo "Conjur plugin config values:"
  echo "  Account: $CONJUR_ACCOUNT"
  echo "  Appliance URL: $CONJUR_APPLIANCE_URL"
  echo "  Auth WebService ID: $SERVICE_ID"
  echo "  Identity Field Name: $TOKEN_APP_PROPERTY"
  echo
  echo
  echo
}

main "$@"
