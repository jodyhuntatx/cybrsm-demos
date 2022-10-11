#!/bin/bash 

export IMAGES="svagi/openssl:latest
cfmanteiga/alpine-bash-curl-jq
postgres:9.4
cyberark/conjur
nginx:1.13.6-alpine
cyberark/conjur-cli:5"

./stop
for img in $IMAGES; do
 docker rmi $img
done
rm -rf conjur-quickstart
