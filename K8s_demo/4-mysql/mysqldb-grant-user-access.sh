#!/bin/bash
if [[ -z "${CONJUR_HOME}" ]]; then
  echo "Set CONJUR_HOME to demo base directory."; exit -1
fi
source $CONJUR_HOME/config/conjur.config

if [[ $# != 3 ]]; then
  echo "Usage: $0 <db-name> <username> <password>"
  exit -1
fi
DB_NAME=$1
DB_UNAME=$2
DB_PWD=\'$3\'
echo "MySQL: Provisioning access for $DB_UNAME to database $DB_NAME..."
set -x  
echo "DROP USER $DB_UNAME; CREATE USER $DB_UNAME IDENTIFIED BY $DB_PWD REQUIRE NONE; GRANT ALL PRIVILEGES ON $DB_NAME.* TO $DB_UNAME;"				\
| $CLI -n $CYBERARK_NAMESPACE_NAME exec -i pod/mysql-db-0 --	\
        mysql -h $DB_URL -u root --password=$MYSQL_ROOT_PASSWORD
