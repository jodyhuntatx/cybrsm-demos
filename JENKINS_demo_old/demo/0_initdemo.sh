#! /bin/bash 
set -eo pipefail

JENKINS_HOSTNAME=jenkins/master
JENKINS_HOST_API_KEY=""
CONJUR_CERT_FILE=~/conjur-$CONJUR_ACCOUNT.pem
KEYSTORE=/opt/java/openjdk/lib/security/cacerts

main() {
  echo "-----"
  init_conjur
  /usr/local/bin/jenkins.sh &> /dev/null &
  echo "Waiting for Jenkins to start up..."
  sleep 15
  echo "Initial Jenkins admin password:" $(cat /var/jenkins_home/secrets/initialAdminPassword)
  keytool -import -alias conjur -keystore $KEYSTORE -file $CONJUR_CERT_FILE
  echo "JENKINS_HOST_API_KEY:" $JENKINS_HOST_API_KEY
}

########################################
init_conjur() {
  conjur init -u $CONJUR_APPLIANCE_URL -a $CONJUR_ACCOUNT --force=true << END
yes
END
  conjur authn login -u $CONJUR_AUTHN_LOGIN -p $CONJUR_ADMIN_PASSWORD
  conjur policy load root policy.yml
  JENKINS_HOST_API_KEY=$(conjur host rotate_api_key --host $JENKINS_HOSTNAME)
}

main "$@"
