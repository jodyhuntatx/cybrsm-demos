#!/bin/bash
source ../spring-demo.config

$DOCKER stop $MYSQL_CONTAINER > /dev/null && $DOCKER rm mysql-db > /dev/null
if [[ "$1" == "clean" ]]; then
  exit 0
fi

$DOCKER run -d 						\
    --name $MYSQL_CONTAINER				\
    -e "MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD"	\
    -p "$MYSQL_PORT:3306"				\
    --restart unless-stopped 				\
    $MYSQL_IMAGE

echo "Waiting for MySQL DB to become available..."
sleep 60

# Set default authentication to pre v8 default
$DOCKER exec $MYSQL_CONTAINER bash -c					\
	"echo 'default_authentication_plugin=mysql_native_password'	\
	>> /etc/mysql/conf.d/mysql.cnf"
