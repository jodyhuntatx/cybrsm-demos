#!/bin/bash
export DOCKER="sudo docker"

if [[ "$1" == "stop" ]]; then
  $DOCKER stop rmqmgr
  $DOCKER rm rmqmgr
  exit 0
fi
if [[ "$($DOCKER ps | grep rmqmgr)" == "" ]]; then
  $DOCKER run -d 		\
	--hostname rmqmgr	\
	-p "4369:4369"		\
	-p "5671:5671"		\
	-p "5672:5672"		\
	-p "15671:15671"	\
	-p "15672:15672"	\
	-p "15691:15691"	\
	-p "15692:15692"	\
 	--name rmqmgr 		\
	rabbitmq:3-management
fi
echo "RabbitMQ node started."
echo "Management web UI at http://$(hostname):15672"
echo "  Username: guest, Password: guest"
