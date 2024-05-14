#!/bin/bash

####################################################
# pcloud-cli.sh - a bash script CLI for Privilege Cloud
####################################################

# use 'curl -v' and 'set -x' for verbose debugging 
export CURL="curl -s"
util_defaults="set -u"

showUsage() {
  echo "Usage:"
  echo "  Safe commands:"
  echo "    $0 safes_list"
  echo "    $0 safe_get <safe-name>"
  echo "    $0 safe_create <safe-name> <description>"
  echo "    $0 safe_member_get <safe-name> <member-name>"
  echo "    $0 safe_admin_add <safe-name> <member-name>"
  echo "    $0 safe_member_delete <safe-name> <member-name>"
  echo "  Account commands:"
  echo "    $0 account_get <safe-name> <account-name>"
  echo "    $0 account_delete <safe-name> <account-name>"
  echo "    $0 account_create_db <safe-name> <platform-id> <account-name> <username> <password>"
  echo "                      [ <server-address> ] [ <database-name> ] [ <server-port> ]"
  echo "    $0 account_create_ssh <safe-name> <platform-id> <account-name> <username> <private-key>"
  echo "                      <server-address>"
  echo "    $0 account_create_aws <safe-name> <platform-id> <account-name> <username> <secret-key>"
  echo "                      <access-key-id> <account-id> [ <region> ] [ <account-alias> ]"
  echo "  Authn commands:"
  echo "    $0 auth_token_get"
  exit -1

# Commands below are partially implemented and mostly don't work.
  echo "    $0 pending_accts_get"
  echo "    $0 pending_accts_set_db "
  echo "    $0 onboarding_rules_get"
  echo "    $0 onboarding_rules_set <rule-name> <rule-description>"
  echo "			<platform-id> <safe-name> <system-type-filter>"
  echo "			<admin-filter> <machine-type-filter>"
  echo "			<username-filter> <username-method>"
  echo "			<address-filter> <address-method>"
  echo "			<acct-category-filter>"
}

main() {
  checkDependencies

  case $1 in
    pending_accts_get | onboarding_rules_get | safes_list)
	command=$1
	;;
    safe_get)
	if [[ $# != 2 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	safeName=$(urlify "$2")
	;;
    safe_create)
	if [[ $# != 3 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	safeName=$(urlify "$2")
	description=$3
	;;
    safe_member_get | safe_member_add | safe_member_delete | safe_admin_add)
	if [[ $# != 3 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	safeName=$(urlify "$2")
	memberName=$(urlify "$3")
	;;
    account_get | account_delete)
	if [[ $# != 3 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	safeName=$(urlify "$2")
	accountName=$(urlify "$3")
	;;
    account_create_db)
	if [[ $# != 9 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	safeName=$(urlify "$2")
	platformId=$(urlify "$3")
	accountName=$(urlify "$4")
	username="$5"
	secret="$6"
	address="$7"
	dbName="$8"
	dbPort="$9"
	;;
    account_create_ssh)
	if [[ $# != 7 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
        safeName=$(urlify "$2")
        platformId=$(urlify "$3")
        accountName=$(urlify "$4")
        username="$5"
        secret="$6"
	address="$7"
	;;
    account_create_aws)
	if [[ $# != 10 ]]; then
	  echo "Incorrect number of arguments."
	  echo $@
	  showUsage
	fi
	command=$1
	safeName=$(urlify "$2")
	platformId=$(urlify "$3")
	accountName=$(urlify "$4")
	username="$5"
	secret="$6"
	accessKeyId="$7"
	accountId="$8"
	region="$9"
	accountAlias="${10}"
	;;
    auth_token_get)
	command=$1
  	pcloud_authenticate
	echo $jwToken
	exit
	;;
    *)
	echo "Unrecognized command: $1"
	showUsage
	;;
  esac

  pcloud_authenticate	# sets global variable authHeader

	# Note that for the function calls below, arguments are accessed globally.
	# They are included here for documentation purpose but not actually passed
	# as function arguments. At some point it may be useful to actually pass 
	# them as parameters.
  case $command in

    safes_list)
	safes_list
	;;

    safe_get)
	safe_get "$safeName"
	;;

    safe_create)
	safe_create "$safeName" "$description"
	;;

    safe_member_get)
	safe_member_get "$safeName" "$memberName"
	;;

    safe_member_add)
	safe_member_add "$safeName" "$memberName"
	;;

    safe_member_delete)
	safe_member_delete "$safeName" "$memberName"
	;;

    safe_admin_add)
	safe_admin_add "$safeName" "$memberName"
	;;

    account_get)
	INTERACTIVE=true
	account_get "$safeName" "$accountName"
	;;

    account_delete)
	account_delete "$safeName" "$accountName"
	;;

    account_create_db)
	account_create_db	"$safeName"	\
        			"$platformId"	\
        			"$accountName"	\
	        		"$address"	\
        			"$username"	\
        			"$secret"	\
      		 		"$dbName"	\
       	 			"$dbPort"	\
	;;

    account_create_ssh)
	account_create_ssh	"$safeName"	\
        			"$platformId"	\
        			"$accountName"	\
	        		"$address"	\
        			"$username"	\
        			"$secret"
	;;

    account_create_aws)
        account_create_aws 	"$safeName"	\
        			"$platformId"	\
        			"$accountName"	\
        			"$username"	\
        			"$secret"	\
        			"accessKeyId"	\
        			"accountId"	\
        			"$region"	\
        			"$accountAlias"
	;;

    pending_accts_get)
	pending_accts_get
	;;

    onboarding_rules_get)
	onboarding_rules_get
	;;

    onboarding_rules_set)
	onboarding_rules_set
	;;

    *)
	showUsage
	;;
  esac
}

#####################################
# sets the global authorization header used in api calls for other methods
function pcloud_authenticate() {
  $util_defaults
  echo "Authenticating user $CYBERARK_ADMIN_USER..."
  jwToken=$($CURL 					\
        -X POST \
        https://$IDENTITY_TENANT_ID.id.cyberark.cloud/oauth2/platformtoken \
        -H "Content-Type: application/x-www-form-urlencoded"      	\
        --data-urlencode "grant_type"="client_credentials"              \
        --data-urlencode "client_id"="$CYBERARK_ADMIN_USER"		\
        --data-urlencode "client_secret"="$CYBERARK_ADMIN_PWD"		\
	| jq -r .access_token)
  authHeader="Authorization: Bearer $jwToken"
}

#####################################
# authns legacy installeruser for non-CyberArk Identity vault access
function installeruser_authenticate() {
  $util_defaults
  sessionToken=$($CURL -X POST 					\
	--header "Content-Type: application/json"		\
	--data "{\"username\":\"$INSTALLERUSER\",	 	\
		\"password\":\"$INSTALLERUSER_PASSWORD\"}"	\
	"${PCLOUD_URL}/auth/Cyberark/Logon/")
  sessionToken=$(echo $sessionToken | tr -d '"')
  authHeader="Authorization: $sessionToken"
}

#####################################
# https://docs.cyberark.com/PrivCloud-SS/Latest/en/Content/WebServices/Get-discovered-accounts.htm
#
function pending_accts_get() {
  $util_defaults

  $CURL -X GET                          		\
	-H "$authHeader"				\
        "${PCLOUD_URL}/DiscoveredAccounts"
  echo
}

#####################################
# https://docs.cyberark.com/PrivCloud-SS/Latest/en/Content/WebServices/GetAutoOnboardingRules.htm
#
function onboarding_rules_get() {
  $util_defaults

  $CURL -X GET                          		\
	-H "$authHeader"				\
        "${PCLOUD_URL}/AutomaticOnboardingRules"
  echo
}

#####################################
# https://docs.cyberark.com/PrivCloud-SS/Latest/en/Content/WebServices/AddAutomaticOnboardingRule.htm
#
function onboarding_rules_set() {
  $util_defaults

  $CURL -X POST                          		\
	-H "$authHeader"				\
        "${PCLOUD_URL}/AutomaticOnboardingRules"
  echo 	'{							\
	"RuleName": "<rule name> - auto-generated if blank",	\
	"RuleDescription": "<description> - optional"		\
	"TargetPlatformId": "<platform ID> - required",		\
	"TargetSafeName": "<Safe name> - required",		\
	"SystemTypeFilter": "<Windows/Unix> - required",	\
	"IsAdminIDFilter": True/False <False>,			\
	"MachineTypeFilter": "Any/Workstation/Server <Server>",	\
	"UserNameFilter": "<filter>",				\
	"UserNameMethod": "Equals/Begins/Ends <Begins>",	\
	"AddressFilter": "<filter>",				\
	"AddressMethod": "Equals/Begins/Ends <Equals>",		\
	"AccountCategoryFilter": "Any/Privileged/Non-privileged <Any>"	\
	}'
}

#####################################
function safes_list() {
  $util_defaults
  $CURL 				\
	-X GET				\
	-H "$authHeader"		\
	"${PCLOUD_URL}/Safes"
}

#####################################
function safe_get() {
  $util_defaults
  printf -v query '.value[] | select(.safeName=="%s")' $safeName
  echo $(safes_list) | jq "$query"
}

#####################################
function safe_create() {
  $util_defaults

  retCode=$($CURL 					\
	-X POST						\
	--write-out '%{http_code}'			\
	--output /dev/null				\
        -H 'Content-Type: application/json'		\
	-H "$authHeader"				\
	"${PCLOUD_URL}/Safes"				\
	-d "{						\
		\"SafeName\":\"$safeName\",		\
		\"NumberOfDaysRetention\":0,		\
		\"Description\":\"$description\"	\
	    }")

  case $retCode in
    201)
        echo "Safe $safeName created."
       ;;
    400)
        echo "$0:safe_create()"
        echo "  Unable to create safe $safeName."
        ;;
    403)
        echo "$0:safe_create()"
        echo "  Unable to create safe $safeName."
        echo "  Check user $CYBERARK_ADMIN_USER is has sufficient permissions."
        exit -1
        ;;
    *)
        echo "$0:safe_create(): Unknown return code: $retCode"
        exit -1
        ;;
  esac

}

#####################################
function safe_member_get() {
  $util_defaults
  $CURL 				\
	-X GET				\
	-H "$authHeader"		\
	"${PCLOUD_URL}/Safes/${safeName}/members/${memberName}/" | jq .
}

#####################################
function safe_member_add() {
  $util_defaults
        $CURL -s \
          --request POST                                        \
	  -H "$authHeader"		\
          --header 'Content-Type: application/json'             \
          ${PCLOUD_URL}/Safes/${safeName}/Members/ 		\
          --data "{                                             \
                \"memberName\":\"$memberName\",                 \
                \"memberType\":\"User\",                        \
                \"permissions\": {                              \
                        \"useAccounts\":true,                   \
                        \"retrieveAccounts\": true,             \
                        \"listAccounts\": true,                 \
                        \"accessWithoutConfirmation\": true     \
                        }                                       \
                }"                                              \
        | jq .
}

#####################################
function safe_admin_add() {
  $util_defaults
        $CURL -s \
          --request POST                                        \
	  -H "$authHeader"		\
          --header 'Content-Type: application/json'             \
          ${PCLOUD_URL}/Safes/${safeName}/Members/ 		\
          --data "{                                             \
                \"memberName\":\"$memberName\",                 \
                \"memberType\":\"User\",                        \
                \"permissions\": {                              \
                        \"accessWithoutConfirmation\": true,		\
                        \"addAccounts\":true,				\
                        \"backupSafe\":true,				\
			\"deleteAccounts\": true,			\
                        \"createFolders\":true,				\
                        \"deleteFolders\":true,				\
		\"initiateCPMAccountManagementOperations\": true,	\
                        \"listAccounts\": true,				\
                        \"manageSafe\": true,				\
                        \"manageSafeMembers\": true,			\
			\"moveAccountsAndFolders\": true,		\
                        \"renameAccounts\": true,			\
                        \"retrieveAccounts\": true,			\
			\"specifyNextAccountContent\": true,		\
			\"unlockAccounts\": true,			\
			\"updateAccountContent\": true,			\
			\"updateAccountProperties\": true,		\
                        \"useAccounts\":true,                   	\
			\"viewAuditLog\": true,				\
			\"viewSafeMembers\": true			\
                        }                                       	\
                }"                                              	\
        | jq .

}

#####################################
function safe_member_delete() {
  $util_defaults

  $CURL 				\
	-X DELETE			\
	-H "$authHeader"		\
	"${PCLOUD_URL}/Safes/$safeName/Members/${memberName}/"
}

#####################################
function account_get {
  $util_defaults

# search example. but you cannott search on account name
#Accounts?limit=1&searchType=StartsWith&search={{ (instance_username + ' ' + instance_ip) | urlencode }}"

  filter=$(urlify "filter=safeName eq ${safeName}")
  printf -v query '.value[] | select(.name=="%s")' $accountName
  response=$($CURL 				\
	-X GET				\
	-H "$authHeader"		\
	"${PCLOUD_URL}/Accounts?$filter" \
	| jq "$query")
  if [[ "$response" == "" && "$INTERACTIVE" == "true" ]]; then
    echo "Account $accountName not found in safe $safeName."
    exit -1
  fi
  echo $response
}

#####################################
function account_delete {
  $util_defaults

  INTERACTIVE=false
  accountInfo=$(account_get $safeName $accountName)
  if [[ "$accountInfo" == "" ]]; then
    echo "Account $accountName not found in safe $safeName."
    exit -1
  fi

  accountId=$(echo $accountInfo | jq -r .id)
  platformId=$(echo $accountInfo | jq -r .platformId)

	# For reasons unknown, you can only delete SSH key accounts
	# with the V1 REST API
  if [[ "$platformId" == "UnixSSHKeys" ]]; then
    retCode=$($CURL 			\
	-X DELETE			\
	--write-out '%{http_code}'	\
	--output /dev/null		\
	-H "$authHeader"		\
	"${PCLOUD_URL_V1}/Accounts/$accountId"
    )
  else
    retCode=$($CURL 			\
	-X DELETE			\
	--write-out '%{http_code}'	\
	--output /dev/null		\
	-H "$authHeader"		\
	"${PCLOUD_URL}/Accounts/$accountId"
    )
  fi

  case $retCode in
    200 | 204)
        echo "Deleted account $accountName in safe $safeName."
       ;;
    400)
        echo "$0:account_delete()"
	echo "  Unable to delete account $accountName in safe $safeName."
        ;;
    403)
        echo "$0:account_delete()"
	echo "  Unable to delete account $accountName in safe $safeName."
	echo "  Check user $CYBERARK_ADMIN_USER is a member of the safe and has sufficient permissions."
        exit -1
        ;;
    405)
        echo "Account with ID $accountId does not exist."
        ;;
    *)
        echo "$0:account_delete: Unknown return code: $retCode"
        exit -1
        ;;
  esac
}

#####################################
function account_create_db {
  $util_defaults

  retCode=$($CURL 					\
	--write-out '%{http_code}'			\
	--output /dev/null				\
	-X POST						\
        -H 'Content-Type: application/json'		\
	-H "$authHeader"				\
	"${PCLOUD_URL}/Accounts"			\
	-d		"{				\
			  \"platformId\": \"$platformId\",	\
			  \"safeName\": \"$safeName\",		\
			  \"name\": \"$accountName\",		\
			  \"address\": \"$address\",		\
			  \"platformAccountProperties\": {	\
			    \"Port\": \"$dbPort\",		\
			    \"Database\": \"$dbName\"		\
			  },					\
			  \"userName\": \"$username\",		\
			  \"secret\": \"$secret\",		\
			  \"secretType\": \"password\",		\
			  \"secretManagement\": {		\
			    \"automaticManagementEnabled\": false,	\
		 	    \"manualManagementReason\": 		\
					\"Auto-onboarding test\"	\
			  }						\
			}"
	)

  case $retCode in
    201)
        echo "Created account $accountName in safe $safeName."
       ;;
    400)
        echo "$0:account_create_db()"
	echo "  Unable to create account $accountName in safe $safeName with platform $platformId."
	echo "  Check if requested platform $platformId is activated in the vault."
        ;;
    409)
        echo "Account already exists. Please confirm values in vault are correct."
        ;;
    403)
        echo "$0:account_create_db()"
	echo "  Unable to create account $accountName in safe $safeName."
	echo "  Check user $CYBERARK_ADMIN_USER is a member of the safe and has sufficient permissions."
        exit -1
        ;;
    *)
        echo "$0:account_create_db: Unknown return code: $retCode"
        exit -1
        ;;
  esac
}

#####################################
function account_create_ssh {
  $util_defaults

  retCode=$($CURL 					\
	-X POST						\
	--output /dev/null				\
	--write-out '%{http_code}'			\
        -H 'Content-Type: application/json'		\
	-H "$authHeader"				\
	"${PCLOUD_URL}/Accounts"			\
	-d		"{				\
			  \"platformId\": \"$platformId\",	\
			  \"safeName\": \"$safeName\",		\
			  \"name\": \"$accountName\",		\
			  \"address\": \"$address\",		\
			  \"userName\": \"$username\",		\
			  \"secret\": \"$secret\",		\
			  \"secretType\": \"key\",		\
			  \"secretManagement\": {		\
			    \"automaticManagementEnabled\": false,	\
		 	    \"manualManagementReason\": 		\
					\"Auto-onboarding test\"	\
			  }						\
			}"
	)

  case $retCode in
    201)
        echo "Created account $accountName in safe $safeName."
       ;;
    400)
        echo "$0:account_create_ssh()"
	echo "  Unable to create account $accountName in safe $safeName with platform $platformId."
	echo "  Check if requested platform $platformId is activated in the vault."
        ;;
    409)
        echo "Account already exists. Please confirm values in vault are correct."
        ;;
    403)
        echo "$0:account_create_ssh()"
	echo "  Unable to create account $accountName in safe $safeName."
	echo "  Check user $CYBERARK_ADMIN_USER is a member of the safe and has sufficient permissions."
        exit -1
        ;;
    *)
        echo "$0:account_create_ssh: Unknown return code: $retCode"
        exit -1
        ;;
  esac
}

#####################################
function account_create_aws {
  $util_defaults

  retCode=$($CURL 					\
	-X POST						\
	--output /dev/null				\
	--write-out '%{http_code}'			\
        -H 'Content-Type: application/json'		\
	-H "$authHeader"				\
	"${PCLOUD_URL}/Accounts"			\
	-d		"{				\
			  \"platformId\": \"$platformId\",	\
			  \"safeName\": \"$safeName\",		\
			  \"name\": \"$accountName\",		\
			  \"userName\": \"$username\",		\
			  \"secret\": \"$secret\",		\
			  \"secretType\": \"key\",		\
                          \"platformAccountProperties\": {      		\
				\"AWSAccountAliasName\": \"$accountAlias\",	\
				\"Region\": \"$region\",			\
				\"AWSAccessKeyID\": \"$accessKeyId\",		\
				\"AWSAccountID\": \"$accountId\"		\
                          },							\
			  \"secretManagement\": {			\
			    \"automaticManagementEnabled\": false,	\
		 	    \"manualManagementReason\": 		\
					\"Auto-onboarding test\"	\
			  }						\
			}"
	)

  case $retCode in
    201)
        echo "Created account $accountName in safe $safeName."
       ;;
    400)
        echo "$0:account_create_aws()"
	echo "  Unable to create account $accountName in safe $safeName with platform $platformId."
	echo "  Check if requested platform $platformId is activated in the vault."
        ;;
    409)
        echo "Account already exists. Please confirm values in vault are correct."
        ;;
    403)
        echo "$0:account_create_aws()"
	echo "  Unable to create account $accountName in safe $safeName."
	echo "  Check user $CYBERARK_ADMIN_USER is a member of the safe and has sufficient permissions."
        exit -1
        ;;
    *)
        echo "$0:account_create_aws: Unknown return code: $retCode"
        exit -1
        ;;
  esac
}

#####################################
# URLIFY - url encodes input string
# in: $1 - string to encode
# out: encoded string on stdout
function urlify() {
        local str=$1; shift
        str=$(echo $str | sed 's= =%20=g')
        str=$(echo $str | sed 's=/=%2F=g')
        str=$(echo $str | sed 's=:=%3A=g')
        str=$(echo $str | sed 's=+=%2B=g')
        str=$(echo $str | sed 's=&=%26=g')
        str=$(echo $str | sed 's=@=%40=g')
        echo $str
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
  if [[ "$IDENTITY_TENANT_ID" == "" ]]; then
    echo
    echo "  IDENTITY_TENANT_ID must be set - e.g. 'xyz1234'"
    all_env_set=false
  fi
  if [[ "$PCLOUD_URL" == "" ]]; then
    echo
    echo "  PCLOUD_URL must be set - e.g. 'https://my-secrets.privilegecloud.cyberark.cloud/api'"
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
