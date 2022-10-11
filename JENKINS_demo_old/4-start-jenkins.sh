#!/bin/bash

source $CONJUR_HOME/config/conjur.config
source ./jenkinsvars.sh

main() {
  pushd build
    ./build.sh
  popd
  start_jenkins
#  config_plugin
}

########################################
start_jenkins() {
  	# create volume for persistence of state across container instances
  if [[ "$($DOCKER volume ls | grep $JENKINS_DEMO_VOLUME)" == "" ]]; then
    $DOCKER volume create $JENKINS_DEMO_VOLUME 
  fi

  if [[ "$($DOCKER ps | grep $JENKINS_DEMO_CONTAINER)" == "" ]]; then
    $DOCKER run -d 							\
      --hostname cbjenkins						\
      --name $JENKINS_DEMO_CONTAINER 					\
      -e "CONJUR_LEADER_HOSTNAME=$CONJUR_CORE_URL"			\
      -e "CONJUR_ACCOUNT=$CONJUR_ACCOUNT"				\
      -e "CONJUR_APPLIANCE_URL=$CONJUR_APPLIANCE_URL"			\
      -e "CONJUR_AUTHN_LOGIN=admin"					\
      -e "CONJUR_AUTHN_API_KEY=$CONJUR_AUTHN_API_KEY"			\
      -e "CONJUR_CERT_FILE=/conjur-cert.pem"				\
      -e "TERM=xterm" 							\
      -p "50000:8080"							\
      --restart always 							\
      --entrypoint "sh" 						\
      $JENKINS_DEMO_IMAGE						\
      -c "sleep infinity"
    docker cp $LEADER_CERT_FILE $JENKINS_DEMO_CONTAINER:/conjur-cert.pem

    $DOCKER exec $JENKINS_DEMO_CONTAINER 	\
	/usr/local/bin/jenkins.sh &> /dev/null &
						# shell for keytool must be interactive
    $DOCKER exec -it -u root $JENKINS_DEMO_CONTAINER	\
	keytool -importcert -alias conjur -keystore $KEYSTORE -file /conjur-cert.pem
  fi
  echo "Waiting for Jenkins to start up..."
  sleep 20 
  clear
  echo
  echo
  echo "======== Configuration info ========="
  echo
  echo "Jenkins URL: http://$JENKINS_PUB_DNS:$JENKINS_PORT"
  echo
  echo -n "Initial Jenkins admin password: "
  echo $($DOCKER exec $JENKINS_DEMO_CONTAINER \
		cat /var/jenkins_home/secrets/initialAdminPassword)
  echo
  echo "Conjur plugin config values:"
  echo "  Account: $CONJUR_ACCOUNT"
  echo "  Appliance URL: $CONJUR_APPLIANCE_URL"
  echo "  Auth WebService ID: $SERVICE_ID"
  echo "  JWT Audience: $JWT_AUDIENCE"
  echo "  Identity Field Name: $TOKEN_APP_PROPERTY"
}


########################################
config_plugin() {
  pluginFolder=$(mktemp -d)

  # Download plugins
  JENKINS_UC=https://updates.jenkins.io REF="${pluginFolder}" \
		install-plugins.sh \
		conjur-credentials:1.0.12

  PLUGIN_PATH=${1}

  STATUS=$(curlJenkins --fail -L -o /dev/null --write-out '%{http_code}' \
          "-F file=@${PLUGIN_PATH}" \
          "${JENKINS_URL}/pluginManager/uploadPlugin") && EXIT_STATUS=$? || EXIT_STATUS=$?
  if [ $EXIT_STATUS != 0 ]
    then
      echo "Installing Plugin failed with exit code: curl: ${EXIT_STATUS}, ${STATUS}"
      exit $EXIT_STATUS
  fi

  echo "${STATUS}"

  # Install all downloaded plugin files via HTTP
  for pluginFile in "${pluginFolder}/plugins"/*; do 
	curl -i -F "file=@${pluginFile}" http://${JENKINS_URL}/pluginManager/uploadPlugin 
  done

cat << END_CONFIG > tmp
<?xml version='1.1' encoding='UTF-8'?>
<org.conjur.jenkins.configuration.GlobalConjurConfiguration plugin="conjur-credentials@1.0.12">
  <conjurConfiguration>
    <applianceURL>https://ec2-35-183-89-55.ca-central-1.compute.amazonaws.com</applianceURL>
    <account>cybrlab</account>
    <credentialID></credentialID>
    <certificateCredentialID></certificateCredentialID>
  </conjurConfiguration>
  <enableJWKS>true</enableJWKS>
  <authWebServiceId>jenkins1</authWebServiceId>
  <jwtAudience>demo</jwtAudience>
  <keyLifetimeInMinutes>60</keyLifetimeInMinutes>
  <tokenDurarionInSeconds>120</tokenDurarionInSeconds>
  <enableContextAwareCredentialStore>true</enableContextAwareCredentialStore>
  <identityFormatFieldsFromToken>jenkins_full_name</identityFormatFieldsFromToken>
  <identityFieldsSeparator>-</identityFieldsSeparator>
  <identityFieldName>jenkins_full_name</identityFieldName>
</org.conjur.jenkins.configuration.GlobalConjurConfiguration>
END_CONFIG
}

main "$@"
