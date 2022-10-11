#!/bin/bash
source ../spring-demo.config

if [[ $# != 1 ]]; then
  echo "Usage: $0 <sql-script-filename>"
  exit -1
fi
dbc=$($DOCKER ps | grep $MYSQL_CLIENT)
if [[ "$dbc" == "" ]]; then
  echo "MySQL client not running."
  exit -1
fi
echo "Loading $1 into MySQL database..."
cat db_create.sql               				\
| $DOCKER exec -i $MYSQL_CLIENT					\
        mysql -h $MYSQL_URL -u root --password=$MYSQL_ROOT_PASSWORD
