#!/bin/bash

source ../../config/conjur.config

$DOCKER stop $MYSQL_SERVER > /dev/null && $DOCKER rm $MYSQL_SERVER > /dev/null
if [[ "$1" == "clean" ]]; then
  exit 0
fi

$DOCKER pull $MYSQL_IMAGE

$DOCKER run -d 						\
    --name $MYSQL_SERVER				\
    -e "MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD"	\
    -p "$MYSQL_PORT:3306"				\
    --restart unless-stopped 				\
    $MYSQL_IMAGE

echo "Waiting for server to finish starting up..."
sleep 20

echo "Initializing MySQL PetStore database..."
cat db_create_petstore.sql                                            \
  | $DOCKER exec -i $MYSQL_SERVER                                     \
        mysql -u root --password=$MYSQL_ROOT_PASSWORD
cat db_load_petstore.sql                                              \
  | $DOCKER exec -i $MYSQL_SERVER                                     \
        mysql -u root --password=$MYSQL_ROOT_PASSWORD
