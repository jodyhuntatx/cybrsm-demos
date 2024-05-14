#!/bin/bash

main() {
  echo "Environment variable values:"
  env | grep ^AWS
  inject_secrets_into_file
}

inject_secrets_into_file() {
  echo
  echo "Contents of AWS_SHARED_CREDENTIALS_FILE:"
  cat $AWS_SHARED_CREDENTIALS_FILE
  echo
  sed -i "s#{{ AWS_ACCESS_KEY_ID }}#$AWS_ACCESS_KEY_ID#" $AWS_SHARED_CREDENTIALS_FILE
  sed -i "s#{{ AWS_SECRET_ACCESS_KEY }}#$AWS_SECRET_ACCESS_KEY#" $AWS_SHARED_CREDENTIALS_FILE
  echo
  echo "Contents of AWS_SHARED_CREDENTIALS_FILE after secrets injection:"
  cat $AWS_SHARED_CREDENTIALS_FILE
  echo
}

main "$@"
