#!/bin/bash
source $CONJUR_HOME/config/conjur.config

while true; do
  echo "Retrieved secret is: $(./var_get_set_REST.sh get secrets/db-password)"
  sleep 5
done
