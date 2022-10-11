#!/bin/bash
source ../../config/conjur.config

if [[ $# != 2 ]]; then
  echo "Usage: $0 <db-name> <username>"
  exit -1
fi
DB_NAME=$1
DB_UNAME=$2
echo "MySQL: Removing access for $DB_UNAME to database $DB_NAME..."
  
echo "REVOKE ALL PRIVILEGES ON $DB_NAME.* FROM $DB_UNAME; DROP USER $DB_UNAME"		\
| $DOCKER exec -i $MYSQL_SERVER	mysql -u root --password=$MYSQL_ROOT_PASSWORD
