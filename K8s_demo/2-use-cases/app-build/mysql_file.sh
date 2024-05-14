#!/bin/bash
DB_HOSTNAME=$(cat /conjur/secrets/secrets.json | jq -r .\"db-hostname\")
DB_NAME=$(cat /conjur/secrets/secrets.json | jq -r .\"db-name\")
DB_UNAME=$(cat /conjur/secrets/secrets.json | jq -r .\"username\")
DB_PWD=$(cat /conjur/secrets/secrets.json | jq -r .\"password\")

echo
echo "DB hostname is: $DB_HOSTNAME"
echo "DB name is: $DB_NAME"
echo "DB username is: $DB_UNAME"
echo "DB password is: $DB_PWD"
echo

set -x
mysql -A -h $DB_HOSTNAME -u $DB_UNAME --password=$DB_PWD $DB_NAME
