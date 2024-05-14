#!/bin/bash
# Ansible Tower demo setup w/ Conjur OSS

export CONJUR_ACCOUNT=myConjurAccount
export CONJUR_ADMIN_PASSWORD=CYberark11@@

# Policy file name, host & variable names created in policy
export TOWER_DEMO_POLICY_FILE=policy/aws-access.yaml
export TOWER_HOST_NAME=tower-job-aws
export AWS_ACCESS_KEY_NAME=aws-access-key
export AWS_SECRET_KEY_NAME=aws-secret-key

main() {
  set_admin_password
  initialize_variables
  print_ansible_config
}

################################
function set_admin_password() {
  pushd conjur-quickstart > /dev/null 2>&1
    # first set admin password to something memorable
    ADMIN_API_KEY=$(cat admin_data | grep "API key" | cut -d : -f 2 | tr -d ' \r\n')
    docker exec conjur_client conjur authn login -u admin -p $ADMIN_API_KEY > /dev/null 2>&1
    docker exec conjur_client conjur user update_password -p $CONJUR_ADMIN_PASSWORD
  popd > /dev/null 2>&1
}

################################
function initialize_variables() {
  cat $TOWER_DEMO_POLICY_FILE \
  | docker exec -i conjur_client conjur policy load root - \
  > /dev/null 2>&1
  TOWER_HOST_API_KEY=$(docker exec conjur_client conjur host rotate_api_key -h $TOWER_HOST_NAME)
  ./conjur-variable set $AWS_ACCESS_KEY_NAME my-aws-access-key
  ./conjur-variable set $AWS_SECRET_KEY_NAME my-aws-secret-key
}

################################
function print_ansible_config() {
  CONJUR_IP_ADDRESS=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

  echo "NAME: Conjur Credential Retriever"
  echo "DESCRIPTION: Conjur credential retriever w/ Conjur OSS"
  echo "ORGANIZATION: <your org or leave blank>"
  echo "CREDENTIAL TYPE: CyberArk Conjur Secret Lookup"
  echo "CONJUR URL: https://proxy:8443"
  echo "CONJUR IP ADDRESS: $CONJUR_IP_ADDRESS"
  echo "API KEY: $TOWER_HOST_API_KEY"
  echo "ACCOUNT: $CONJUR_ACCOUNT"
  echo "USERNAME: host/$TOWER_HOST_NAME"
  echo "PUBLIC KEY CERTIFICATE:" 
  openssl s_client -showcerts -connect localhost:8443 < /dev/null 2> /dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' 
  echo "Variable names:"
  docker exec conjur_client conjur list -k variable
  echo "Host names:"
  docker exec conjur_client conjur list -k host
}

main "$@"
