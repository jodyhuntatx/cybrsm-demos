#!/bin/bash
source ../spring-demo.config

$DOCKER stop $MYSQL_CLIENT > /dev/null && $DOCKER rm $MYSQL_CLIENT > /dev/null
if [[ "$1" == "clean" ]]; then
  exit 0
fi

cd build
  ./build.sh
cd ..

# Client for admin and app simulation
$DOCKER run -d			\
    --name $MYSQL_CLIENT	\
    --add-host "$CONJUR_LEADER_HOSTNAME:$CONJUR_LEADER_HOST_IP" \
    -e "DB_URL=$MYSQL_URL"	\
    -e "TERM=xterm"		\
    --restart unless-stopped 	\
    --entrypoint "sh"		\
    $MYSQL_CLIENT_IMAGE		\
    -c "sleep infinity"
