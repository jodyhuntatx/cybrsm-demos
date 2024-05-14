#!/bin/bash
ROLE_TYPES="policy group user host"
if [[ $# != 1 ]]; then
  echo "Usage: $0 < policy | group | user | host >"
  exit -1
fi
if [[ "$ROLE_TYPES" =~ (^|[[:space:]])"$1"($|[[:space:]]) ]]; then
  ROLE_FILTER=$1
else
  echo "Usage: $0 < policy | group | user | host >"
  exit -1
fi

VAR_LIST=$(docker exec conjur-cli conjur list -k variable | jq -r .[])
for i in $VAR_LIST; do
  varname=$(echo $i | cut -d: -f3)
  echo "Variable: $i"
  echo "  Roles with UPDATE access:"
  ROLE_LIST=$(docker exec conjur-cli conjur resource permitted_roles $i update | jq -r .[])
  for j in $ROLE_LIST; do
    roletype=$(echo $j | cut -d: -f2)
    if [[ $roletype != $ROLE_FILTER ]]; then
      continue
    fi
    rolename=$(echo $j | cut -d: -f3)
    echo "    $roletype:$rolename"
  done

  echo "  Roles with READ access:"
  ROLE_LIST=$(docker exec conjur-cli conjur resource permitted_roles $i read | jq -r .[])
  for j in $ROLE_LIST; do
    roletype=$(echo $j | cut -d: -f2)
    if [[ $roletype != $ROLE_FILTER ]]; then
      continue
    fi
    rolename=$(echo $j | cut -d: -f3)
    echo "    $roletype:$rolename"
  done
  echo "============================"
done
