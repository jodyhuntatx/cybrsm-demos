#!/bin/bash -e
source ../../../config/conjur.config

cat templates/secrets.template.yml				\
  | sed -e "s#{{ ACCOUNT_USERNAME }}#$ACCOUNT_USERNAME#g"       \
  | sed -e "s#{{ ACCOUNT_PASSWORD }}#$ACCOUNT_PASSWORD#g"       \
  | sed -e "s#{{ ACCOUNT_ADDRESS }}#$ACCOUNT_ADDRESS#g"       \
  > secrets.yml

docker build -t $APP_IMAGE .
