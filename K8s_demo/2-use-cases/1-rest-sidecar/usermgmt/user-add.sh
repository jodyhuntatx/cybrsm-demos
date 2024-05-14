#!/bin/bash

if [ $# != 3 ]; then
  echo "Usage: $0 <project-name> <username> <password>"
  exit -1
fi
pname=$1
uname=$2
upwd=$3
set -x
userjson=$(cat user-add.yml		\
| sed -e "s#{{ USERNAME }}#$uname#g"	\
| sed -e "s#{{ PROJECTNAME }}#$pname#g"	\
| docker exec -i conjur-cli conjur policy load root -)
uapikey=$(echo $userjson | grep api_key | cut -d: -f 2 | tr -d '"')
docker exec -i conjur-cli conjur authn login -u $uname -p $uapikey
