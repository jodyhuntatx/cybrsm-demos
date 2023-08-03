#!/bin/bash

source $CONJUR_HOME/config/conjur.config
source ../jenkinsvars.sh

main() {
  pushd build
    ./build.sh
  popd
  start_container
#  setup_https
  start_jenkins
  display_config_info
}

########################################
start_jenkins() {
    $DOCKER exec $JENKINS_DEMO_CONTAINER 	\
	service jenkins start

  echo "Waiting for Jenkins to start up..."
  sleep 20 
  init_jenkins
}

########################################
start_container() {
  if [[ "$($DOCKER ps | grep $JENKINS_DEMO_CONTAINER)" == "" ]]; then
    $DOCKER run -d 							\
      --hostname $JENKINS_DEMO_CONTAINER				\
      --name $JENKINS_DEMO_CONTAINER 					\
      -e "CONJUR_LEADER_HOSTNAME=$CONJUR_CORE_URL"			\
      -e "CONJUR_ACCOUNT=$CONJUR_ACCOUNT"				\
      -e "CONJUR_APPLIANCE_URL=$CONJUR_APPLIANCE_URL"			\
      -e "CONJUR_AUTHN_LOGIN=admin"					\
      -e "CONJUR_AUTHN_API_KEY=$CONJUR_AUTHN_API_KEY"			\
      -e "CONJUR_CERT_FILE=/conjur-cert.pem"				\
      -e "TERM=xterm" 							\
      -p "$JENKINS_PORT:8080"						\
      -p "$JENKINS_HTTPS_PORT:443"					\
      --restart always 							\
      --entrypoint "sh" 						\
      $JENKINS_DEMO_IMAGE						\
      -c "sleep infinity"
  fi
}

########################################
init_jenkins() {
  $DOCKER cp $LEADER_CERT_FILE $JENKINS_DEMO_CONTAINER:/conjur-cert.pem

  echo
  echo
  echo "Keystore Password is: changeit"
  echo
  echo
						# shell for keytool must be interactive
  $DOCKER exec -itu root $JENKINS_DEMO_CONTAINER	\
	keytool -importcert -alias conjur -keystore $KEYSTORE -file /conjur-cert.pem
}


########################################
setup_https() {
    # create keystore for HTTPS certificate
    $DOCKER exec -it $JENKINS_DEMO_CONTAINER bash -c	\
	"cd /tmp;
	openssl req -newkey rsa:2048 -nodes -keyout key.pem -x509 -days 365 -out certificate.pem;
	openssl pkcs12 -inkey key.pem -in certificate.pem -export -out certificate.p12;
	keytool -importkeystore -srckeystore ./certificate.p12 -srcstoretype pkcs12 -destkeystore jenkins.jks -deststoretype JKS;
	cp jenkins.jks /var/lib/jenkins;
	chown jenkins:jenkins /var/lib/jenkins/jenkins.jks"

    # change service file to enable HTTPS
    $DOCKER exec $JENKINS_DEMO_CONTAINER 	\
	sed -i "/^#Environment=\"JENKINS_HTTPS_PORT/s/.*/Environment=\"JENKINS_HTTPS_PORT=443\"/g" /etc/systemd/system/multi-user.target.wants/jenkins.service

    $DOCKER exec $JENKINS_DEMO_CONTAINER 	\
	sed -i "/^#Environment=\"JENKINS_HTTPS_KEYSTORE=/s/.*/Environment=\"JENKINS_HTTPS_KEYSTORE=\/var\/lib\/jenkins\/jenkins.jks\"/g" /etc/systemd/system/multi-user.target.wants/jenkins.service

    $DOCKER exec $JENKINS_DEMO_CONTAINER 	\
	sed -i "/^#Environment=\"JENKINS_HTTPS_KEYSTORE_PASSWORD/s/.*/Environment=\"JENKINS_HTTPS_KEYSTORE_PASSWORD=changeit\"/g" /etc/systemd/system/multi-user.target.wants/jenkins.service
}

########################################
display_config_info() {
  echo
  echo
  echo
  echo
  echo "======== Configuration info ========="
  echo
  echo "Jenkins URL: http://$JENKINS_PUB_DNS:$JENKINS_PORT"
  echo
  echo -n "Initial Jenkins admin password: "
  echo $($DOCKER exec $JENKINS_DEMO_CONTAINER \
	cat /var/lib/jenkins/secrets/initialAdminPassword)
  echo
  echo "Conjur plugin config values:"
  echo "  Account: $CONJUR_ACCOUNT"
  echo "  Appliance URL: $CONJUR_APPLIANCE_URL"
  echo "  Auth WebService ID: $SERVICE_ID"
  echo "  JWT Audience: $JWT_AUDIENCE"
  echo "  Identity Field Name: $TOKEN_APP_PROPERTY"
  echo
  echo
  echo
}

main "$@"
