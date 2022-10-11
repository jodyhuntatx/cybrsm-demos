#!/bin/bash
ROLE_TYPES="policy group user host"
RESOURCE_TYPES="variable host user webservice group policy"
if [[ $# != 2 ]]; then
  echo "Usage: $0 <role-type> <resource-type>"
  echo "  where"
  echo "    role-type is one of: host, group, user, layer"
  echo "    resource-type is one of: variable, host, user, webservice, group, policy"
  exit -1
fi
ROLE_FILTER=""
RESOURCE_FILTER=""
if [[ "$ROLE_TYPES" =~ (^|[[:space:]])"$1"($|[[:space:]]) ]]; then
  ROLE_FILTER=$1
fi
if [[ "$RESOURCE_TYPES" =~ (^|[[:space:]])"$2"($|[[:space:]]) ]]; then
  RESOURCE_FILTER=$2
fi
if [[ (-z $ROLE_FILTER) || (-z $RESOURCE_FILTER) ]]; then
  echo "Usage: $0 < policy | group | user | host >"
  exit -1
fi
ROLE_LIST=$(docker exec conjur-cli conjur list -k $ROLE_FILTER | jq -r .[])
for i in $ROLE_LIST; do
  rolename=$(echo $i | cut -d: -f3)
  echo "Role $ROLE_FILTER:$rolename access to resource type $RESOURCE_FILTER:"
  RESOURCE_LIST=$(docker exec conjur-cli conjur list --role=$i -k $1 | jq -r .[])
  for j in $RESOURCE_LIST; do
    resourcename=$(echo $j | cut -d: -f3)
    echo "    $RESOURCE_FILTER:$resourcename"
  done
  echo "============================"
done
