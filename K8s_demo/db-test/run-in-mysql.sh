#!/bin/bash

source ../../config/conjur.config

export NAMESPACE=$APP_NAMESPACE_NAME
export POD_NAME=app-example-secretless-7745c46866-x8qgg
#export REDIRECT="/dev/tty"
export REDIRECT="/dev/null"

main() {
  if [[ $# != 2 ]]; then
    echo "Usage: $0 <sql-command-filename> <num-iterations>"
    exit -1
  fi
  export SQL_CMD_FILE=$1
  export NUM_ITERATIONS=$2

  if [[ "$PLATFORM" == "openshift" ]]; then
    $CLI login -u $CLUSTER_ADMIN
  fi

  echo
  echo "Direct connection:"
  time run_test $NAMESPACE $POD_NAME $DB_URL $SQL_CMD_FILE $NUM_ITERATIONS
  echo
  echo "Secretless connection:"
  time run_test $NAMESPACE $POD_NAME 127.0.0.1 $SQL_CMD_FILE $NUM_ITERATIONS
}

run_test() {
  local NS=$1; shift;
  local POD=$1; shift;
  local DB=$1; shift;
  local FN=$1; shift;
  local NUM=$1; shift;

  for i in $(seq 1 $NUM); do
    cat $FN								\
    | $CLI -n $NS exec -i $POD -c app-example-secretless --		\
        mysql -h $DB -u $MYSQL_USERNAME --password=$MYSQL_PASSWORD &> $REDIRECT
  done
}

main "$@"
