#!/bin/bash

####################################################
# shub-cli.sh - a bash script CLI for Secrets Hub
####################################################

CYBRVAULT_CLI=~/Conjur/cybrsm-demos/bin/cybrvault-cli.sh

export CURL="curl -s"

showUsage() {
  echo "Usage:"
  echo
  echo "  Secret Stores commands:"
  echo "    $0 stores_get - returns all store records in tenant."
  echo "    $0 stores_sources_get - returns all secrets store sources."
  echo "    $0 stores_targets_get - returns all secrets store targets."
  echo "    $0 stores_name_id - returns just store names and IDs."
  echo "    $0 store_id_get \"<store-name-in-quotes>\" - gets just the store ID."
  echo "    $0 store_get <store-id> - returns individual store record."
  echo "    $0 store_status <store-id> - returns connection status for store."
  echo "    $0 store_create <type> <account-alias> <account-id> <region> <role-name> <description> <name> NOT IMPLEMENTED YET"
  echo "    $0 store_delete <store-id> NOT IMPLEMENTED YET"
  echo
  echo "  Secrets Filter commands:"
  echo "    NOTE: Filter commands only work for SECRETS_SOURCE."
  echo "    $0 filters_get <source-store-id>"
  echo "    $0 filter_get <source-store-id> <filter-id>"
  echo "    $0 filters_create <source-store-id>"
  echo "    $0 filter_delete <source-store-id> <filter-id>"
  echo
  echo "  Sync Policy commands:"
  echo "    $0 policies_get"
  echo "    $0 policies_name_id"
  echo "    $0 policies_target_get <target-store-id>"
  echo "    $0 policy_get <policy-id>"
  echo "    $0 policy_create <name> <description> <source-store-id> <target-store-id> <filter-id>"
  echo "    $0 policy_state <policy-id> <action>"
  echo "    $0 policy_delete <policy-id>"
  echo
  echo "  Scan commands:"
  echo "    $0 scan_secrets"
  echo "    $0 scan_trigger <scan-type> <scan-id> '<comma-separated-secret-store-id-list>'"
  echo "    $0 scan_track"
  echo
  echo "  Tenant commands:"
  echo "    $0 tenant_info"
  echo
  echo "  Authn commands:"
  echo "    $0 auth_token_get"
  exit -1
}

main() {
  checkDependencies

  case $1 in
    auth_token_get)
	echo $($CYBRVAULT_CLI auth_token_get)
	exit 0
	;;
    tenant_info | stores_sources_get | stores_targets_get | stores_get | stores_name_id | policies_get | policies_name_id)
	command=$1
	;;
    store_get | store_status | store_delete | policies_source_get| policies_target_get | filters_get)
	if [[ $# != 2 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	storeId=$2
	;;
    store_id_get)
	if [[ $# != 2 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	storeName="$2"
	;;
    filter_get)
	if [[ $# != 3 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	storeId=$2
	filterId=$3
	;;
    filter_create)
	if [[ $# != 3 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	storeId=$2
	safeName=$3
	;;
    filter_delete)
	if [[ $# != 3 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	storeId=$2
	filterId=$3
	;;
    policy_get | policy_delete)
	if [[ $# != 2 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	policyId=$2
	;;
    policy_state)
	if [[ $# != 3 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	policyId=$2
	action=$3
	;;
    policy_create)
	if [[ $# != 6 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	name=$2
	description=$3
	sourceStoreId=$4
	targetStoreId=$5
	filterId=$6
	;;
    scan_secrets | scan_track)
	command=$1
	;;
    scan_trigger)
	if [[ $# != 4 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	scanType=$2
	scanId=$3
	secretStoreIdList="$4"
	;;
    *)
	echo "Unrecognized command: $1"
	showUsage
	;;
  esac

  authToken=$($CYBRVAULT_CLI auth_token_get)
  authHeader="Authorization: Bearer $authToken"

set -x
  case $command in

    tenant_info)
        $CURL -X GET                          		\
	  -H "$authHeader"				\
          "${CYBERARK_SHUB_API}/info"
	;;

    stores_sources_get)
        $CURL -X GET                          		\
	  -H "$authHeader"				\
          "${CYBERARK_SHUB_API}/secret-stores"		\
	| jq '.secretStores[] | select(any(.behaviors[] == "SECRETS_SOURCE"; .))'
	;;

    stores_targets_get)
        $CURL -X GET                          		\
	  -H "$authHeader"				\
          "${CYBERARK_SHUB_API}/secret-stores"		\
	| jq '.secretStores[] | select(any(.behaviors[] == "SECRETS_TARGET"; .))'
	;;

    stores_get)
        $CURL -X GET                          		\
	  -H "$authHeader"				\
          "${CYBERARK_SHUB_API}/secret-stores"
	;;

    stores_name_id)
        $CURL -X GET                          		\
	  -H "$authHeader"				\
          "${CYBERARK_SHUB_API}/secret-stores"		\
	| jq -r '.secretStores[] | "Store name: \(.name)\n  Store ID: \(.id)"'
	;;

    store_get)
	$CURL -X GET                          		\
	  -H "$authHeader"				\
          "${CYBERARK_SHUB_API}/secret-stores/$storeId"
	;;

    store_id_get)
	printf -v query '.secretStores[] | select(.name=="%s") | .id' "$storeName"
	$CURL -X GET                          		\
	  -H "$authHeader"				\
          "${CYBERARK_SHUB_API}/secret-stores"		\
	| jq -r "$query"
	;;

    store_status)
	$CURL -X GET                          		\
	  -H "$authHeader"				\
          "${CYBERARK_SHUB_API}/secret-stores/$storeId/status/connection"
	;;

    filters_get)
	$CURL -X GET                          		\
	  -H "$authHeader"				\
          "${CYBERARK_SHUB_API}/secret-stores/$storeId/filters"
	;;

    filter_get)
	$CURL -X GET                          		\
	  -H "$authHeader"				\
          "${CYBERARK_SHUB_API}/secret-stores/$storeId/filters/$filterId"
	;;

    filter_create)
	$CURL -X POST                          		\
	  -H "$authHeader"				\
          "${CYBERARK_SHUB_API}/secret-stores/$storeId/filters"	\
	  -d "{						\
		\"data\": {				\
			\"safeName\": \"$safeName\"	\
		},					\
		\"type\": \"PAM_SAFE\"			\	
	      }"
	;;

    filter_delete)
	$CURL -X DELETE                        		\
	  -H "$authHeader"				\
          "${CYBERARK_SHUB_API}/secret-stores/$storeId/filters/$filterId"
	;;

    policies_get)
	$CURL -X GET                          		\
	  -H "$authHeader"				\
          "${CYBERARK_SHUB_API}/policies"
	;;

    policies_target_get)
	printf -v query '.policies[] | select(.target.id=="%s")' "$storeId"
	$CURL -X GET                          		\
	  -H "$authHeader"				\
          "${CYBERARK_SHUB_API}/policies"			\
	| jq -r "$query"
	;;

    policies_name_id)
        $CURL -X GET                          		\
	  -H "$authHeader"				\
          "${CYBERARK_SHUB_API}/policies"			\
	| jq -r '.policies[] | "Policy name: \(.name)\n  Policy ID: \(.id)"'
	;;

    policy_get)
	$CURL -X GET                          		\
	  -H "$authHeader"				\
          "${CYBERARK_SHUB_API}/policies/$policyId"
	;;

    policy_state)
	$CURL -X PUT                          		\
	  -H "$authHeader"				\
          "${CYBERARK_SHUB_API}/policies/$policyId/state"	\
	  -d "{ \"action\": \"$action\" }"
	;;

    policy_delete)
	$CURL -X DELETE                        		\
	  -H "$authHeader"				\
          "${CYBERARK_SHUB_API}/policies/$policyId"
	;;

    policy_create)
	$CURL -X POST					\
	  -H "$authHeader"				\
          "${CYBERARK_SHUB_API}/policies"			\
	  -d "{						\
		\"name\": \"$name\",			\
		\"description\": \"$description\",	\
		\"source\": {
			\"id\": \"$sourceStoreId\"	\
		},					\
		\"target\": {				\
			\"id\": \"$targetStoreId\"	\
		},					\
		\"filter\": {				\
			\"id\": \"$filterId\"		\
		}					\
	     }"
        ;;

    scan_secrets)
	$CURL -X GET						\
	  -H "$authHeader"					\
	  -H "Accept: application/x.secretshub.beta+json"	\
          "${CYBERARK_SHUB_API}/secrets?projection=EXTEND"
	;;
    scan_trigger)
	$CURL -X POST						\
	  -H "$authHeader"					\
	  -H "Accept: application/x.secretshub.beta+json"	\
	  -H "Content-Type: application/json"			\
          "${CYBERARK_SHUB_API}/scan-definitions/$scanType/$scanId/scan" \
	  -d "{  \"scope\": {
		  \"secretStoresIds\": [
		    $secretStoreIdList
		  ]
		}
	     }"
	;;
    scan_track)
	$CURL -X GET						\
	  -H "$authHeader"					\
	  -H "Accept: application/x.secretshub.beta+json"	\
          "${CYBERARK_SHUB_API}/scans"
	;;
    *)
	showUsage
	;;
  esac
}

#####################################
# verifies jq installed & required environment variables are set
function checkDependencies() {
  all_env_set=true
  if [[ "$(which jq)" == "" ]]; then
    echo
    echo "The JSON query utility jq is required. Please install jq."
    all_env_set=false
  fi
  if [[ "$CYBERARK_IDENTITY_URL" == "" ]]; then
    echo
    echo "  CYBERARK_IDENTITY_URL must be set."
    all_env_set=false
  fi
  if [[ "$CYBERARK_SHUB_API" == "" ]]; then
    echo
    echo "  CYBERARK_SHUB_API must be set - e.g. 'https://my-secrets.secretshub.cyberark.cloud/api'"
    all_env_set=false
  fi
  if [[ "$CYBERARK_ADMIN_USER" == "" ]]; then
    echo
    echo "  CYBERARK_ADMIN_USER must be set - e.g. foo_bar@cyberark.cloud.7890"
    echo "    This MUST be a Service User and Oauth confidential client."
    echo "    This script will not work for human user identities."
    all_env_set=false
  fi
  if [[ "$CYBERARK_ADMIN_PWD" == "" ]]; then
    echo
    echo "  CYBERARK_ADMIN_PWD must be set to the $CYBERARK_ADMIN_USER password."
    all_env_set=false
  fi
  if ! $all_env_set; then
    echo
    exit -1
  fi
}

main "$@"
