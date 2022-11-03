#!/bin/bash
if [[ -z "${CONJUR_HOME}" ]]; then
  echo "Set CONJUR_HOME to demo base directory."; exit -1
fi
source $CONJUR_HOME/config/conjur.config

  echo "Initializing MySQL database..."
  # create db
  cat db_create_petclinic.sql          				\
  | $CLI -n $CYBERARK_NAMESPACE_NAME exec -i pod/mysql-db-0 --	\
        mysql -h localhost -u root --password=$MYSQL_ROOT_PASSWORD
  # load data
  cat db_load_petclinic.sql            				\
  | $CLI -n $CYBERARK_NAMESPACE_NAME exec -i pod/mysql-db-0 --	\
        mysql -h localhost -u root --password=$MYSQL_ROOT_PASSWORD
  # grant user access
  quoted_pwd=\'$MYSQL_PASSWORD\'
  echo "DROP USER IF EXISTS $MYSQL_USERNAME; CREATE USER $MYSQL_USERNAME IDENTIFIED BY $quoted_pwd REQUIRE NONE; GRANT ALL PRIVILEGES ON $MYSQL_DBNAME.* TO $MYSQL_USERNAME;"		\
  | $CLI -n $CYBERARK_NAMESPACE_NAME exec -i pod/mysql-db-0 --	\
        mysql -h localhost -u root --password=$MYSQL_ROOT_PASSWORD
