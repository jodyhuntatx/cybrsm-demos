#!/bin/bash

# Creates resources needed for all demos

source $CONJUR_HOME/config/conjur.config
source ../cloudbeesvars.sh
	
main() {
  cybr conjur logon-non-interactive
  create_base_policy_for_apps	# Conjur base policy
}

########################
create_base_policy_for_apps() {
  # Create base policy for app ids
  cat > ./tmp << END_POLICY
- !host
  id: safe_bot

- !group
  id: automation

- !grant
  role: !group $VAULT_NAME-admins
  member: !group automation

- !grant
  role: !group automation
  member: !host safe_bot

- !policy
  id: apps
  owner: !group automation
  body:
  - !group authenticators
END_POLICY
  cybr conjur append-policy -b root -f ./tmp
  rm ./tmp
}

main "$@"
