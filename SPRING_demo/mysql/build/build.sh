#!/bin/bash -e
source ../../spring-demo.config
docker build -t $MYSQL_CLIENT_IMAGE .
