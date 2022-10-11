# CloudBees Jenkins demo vars
export DOCKER=docker
export CLOUDBEES_DEMO_IMAGE=cloudbeesdemo
export CLOUDBEES_DEMO_CONTAINER=cbjenkins
export CLOUDBEES_DEMO_VOLUME=cbjenkins
export CLOUDBEES_JENKINS_HOME=/var/lib/jenkins	# mountpoint for data volume to preserve state
export KEYSTORE=/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/cacerts
export WORKDIR=/tmp
export CLOUDBEES_PUB_DNS=conjur-master-minikube
export CLOUDBEES_PORT=8080

######################
# Vault policy parameters & secrets
export VAULT_NAME=DemoVault
export LOB_NAME=CICD
export SAFE_NAME=CICD_Secrets
export ACCOUNT_NAME=MySQL

export MYSQL_ROOT_PASSWORD=Cyberark1
export MYSQL_SERVER=mysql-server
export MYSQL_PORT=3306
export MYSQL_USERNAME=${SAFE_NAME}_user1
export MYSQL_PASSWORD=UHGMLk1
export MYSQL_DBNAME=petclinic
# Get private IP of jumpbox from well-known AWS metadata service
export MYSQL_URL=$CLOUDBEES_PUB_DNS

###########################
# authn-jwt config values
export SERVICE_ID=cbjenkins
export JWT_POLICY_TEMPLATE=authn-jwt.yml.template
export JWKS_URI=http://$CLOUDBEES_PUB_DNS:$CLOUDBEES_PORT/jwtauth/conjur-jwk-set
export TOKEN_APP_PROPERTY=jenkins_full_name
export IDENTITY_PATH=/apps
export JWT_ISSUER=http://$CLOUDBEES_PUB_DNS:$CLOUDBEES_PORT
export JWT_AUDIENCE=demo

# Login as admin to rotate safe_bot API key (avoids storing it)
get_safe_bot_api_key() {
  cybr conjur logon-non-interactive >& /dev/null
  if [ $? -ne 0 ]; then
    echo "Error logging into Conjur as admin."
    exit -1
  fi
  echo $(cybr conjur rotate-api-key -l host/safe_bot)
}

