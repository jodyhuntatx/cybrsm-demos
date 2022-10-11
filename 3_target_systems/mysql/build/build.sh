#!/bin/bash -e
source ../../../config/conjur.config
docker build -t $MYSQL_CLIENT_IMAGE .
