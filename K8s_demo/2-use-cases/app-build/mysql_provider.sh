#!/bin/bash
DB_HOSTNAME=$(cat /etc/secret-volume/db-hostname)
DB_NAME=$(cat /etc/secret-volume/db-name)
DB_UNAME=$(cat /etc/secret-volume/username)
DB_PWD=$(cat /etc/secret-volume/password)
echo
echo "DB hostname is: $DB_HOSTNAME"
echo "DB name is: $DB_NAME"
echo "DB username is: $DB_UNAME"
echo "DB password is: $DB_PWD"
echo
set -x
mysql -h $DB_HOSTNAME -u $DB_UNAME --password=$DB_PWD $DB_NAME
