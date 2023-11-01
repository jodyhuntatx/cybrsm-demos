#!/bin/bash

source ./env-vars.sh

CYBRID_CLI=~/Conjur/cybrsm-demos/bin/cybrid-cli.sh
CYBRVAULT_CLI=~/Conjur/cybrsm-demos/bin/cybrvault-cli.sh

NAMEROOT=CybrUser
PWDROOT=CybrUser
USERROLE=WorkshopUser
NUMUSERS=3

main() {
  case $1 in
    p | provision)
      provision
      ;;
    d | deprovision)
      deprovision
      ;;
    r | report)
      report
      ;;
    *)
      echo "Usage: $0 [ p | d | r ]"
      echo "  Enter p[rovision], d[eprovision] or r[eport] command."
      exit -1
  esac
}

###################
provision() {
  i=1
  while [[ $i != $NUMUSERS ]]; do
    USERNAME=$NAMEROOT$i@$TENANT_DOMAIN
    PASSWORD=$PWDROOT$i
    SAFENAME=$NAMEROOT$i
    echo "Creating user $USERNAME with password $PASSWORD and role $USERROLE..."
    result=$($CYBRID_CLI user_create $USERNAME $PASSWORD "Secrets Hub Immersion Day user")
    success=$(echo $result | jq -r .success)
    if [[ "$success" != "true" ]]; then
      echo $(echo $result | jq -r .Message)
    fi
    result=$($CYBRID_CLI user_role_add $USERNAME $USERROLE)
    success=$(echo $result | jq -r .success)
    if [[ "$success" != "true" ]]; then
      echo $(echo $result | jq -r .Message)
    fi
    echo "User $USERNAME created."
    $CYBRVAULT_CLI safe_create $SAFENAME "Secrets Hub Immersion Day safe"
    $CYBRVAULT_CLI safe_admin_add $SAFENAME $USERNAME > /dev/null
    let i=i+1
  done
}

###################
deprovision() {
  i=1
  while [[ $i != $NUMUSERS ]]; do
    USERNAME=$NAMEROOT$i@$TENANT_DOMAIN
    PASSWORD=$PWDROOT$i
    SAFENAME=$NAMEROOT$i

    echo "Deleting user $USERNAME..."
    result=$($CYBRID_CLI user_remove $USERNAME)
    success=$(echo $result | jq -r .success)
    if [[ "$success" != "true" ]]; then
      echo $result
    fi
    result=$($CYBRVAULT_CLI safe_delete $SAFENAME)
    if [[ "$result" != "" ]]; then
      echo $result
    fi
    let i=i+1
  done
}

###################
report() {
  echo
  $CYBRID_CLI user_list | jq -r .[].Row.Name
  echo
}

main "$@"
