#!/bin/bash

parse_file() {
  fname=$1; shift
  str=$1; shift
  cat $fname | grep $str | awk '{print $2}' | tr -d '"'
}

export CONJUR_ACCOUNT=$(parse_file /etc/conjur.conf account)
export CONJUR_APPLIANCE_URL=$(parse_file /etc/conjur.conf appliance)
export CONJUR_CERT_FILE=$(parse_file /etc/conjur.conf cert_file)
export CONJUR_AUTHN_LOGIN=$(parse_file /etc/conjur.identity login)
export CONJUR_AUTHN_API_KEY=$(parse_file /etc/conjur.identity password)

ansible-playbook -i inventory.yml demoPlaybook.yml
