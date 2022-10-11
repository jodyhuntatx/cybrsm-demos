#!/bin/bash

function main() {
  ./load_policy_REST.sh root policy/azure-authn.yml delete
  ./var_value_add_REST.sh conjur/authn-azure/jdemo/provider-uri "https://sts.windows.net/dc5c35ed-5102-4908-9a31-244d3e0134c6/"
  sudo docker exec conjur-master evoke variable set CONJUR_AUTHENTICATORS authn-azure/jdemo
}

main "$@"
