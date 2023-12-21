#!/bin/bash

show_usage() {
  echo "Usage:"
  echo "  $0 secrets_managed_get <region>"
  echo "  $0 secrets_unmanaged_get <region>"
  echo "  $0 secret_describe <region> <name>"
  exit -1
}

case $1 in
  secrets_managed_get)
	if [[ $# != 2 ]]; then
	  show_usage
	fi
	command=$1
	region=$2
	aws --region $region secretsmanager list-secrets	\
	| jq '.SecretList[] | select(any(.Tags[].Key == "Sourced by CyberArk"; .))'
	;;

  secrets_unmanaged_get)
	if [[ $# != 2 ]]; then
	  show_usage
	fi
	command=$1
	region=$2
	aws --region $region secretsmanager list-secrets	
#\
#	| jq '.SecretList[] | select(any(.Tags[].Key == "Sourced by CyberArk"; .) | not)'
	;;

  secret_describe)
	if [[ $# != 3 ]]; then
	  show_usage
	fi
	command=$1
	region=$2
	name=$3
	aws --region $region secretsmanager describe-secret --secret-id $name --no-paginate
	aws --region $region secretsmanager get-secret-value --secret-id $name --no-paginate
	;;

  *)
	echo "Unrecognized command: $1"
	show_usage
	;;
esac
