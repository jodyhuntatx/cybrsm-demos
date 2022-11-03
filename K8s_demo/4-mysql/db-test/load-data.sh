#!/bin/bash

source ../../config/conjur.config

export NAMESPACE=$APP_NAMESPACE_NAME
export POD_NAME=app-example-secretless-7745c46866-x8qgg

main() {
  if [[ "$PLATFORM" == "openshift" ]]; then
    $CLI login -u $CLUSTER_ADMIN
  fi
set -x
  cat test_data.sql               				\
  | $CLI -n $NAMESPACE exec -i $POD_NAME --			\
        mysql -h $DB_URL -u root --password=$MYSQL_ROOT_PASSWORD
}

main "$@"
