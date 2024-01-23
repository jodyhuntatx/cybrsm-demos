#!/bin/bash

####################################################
# cybrvault-cli.sh - 
# A bash script CLI for CybrArk Self-Hosted and Privilege Cloud Vaults
####################################################

SELF_HOSTED_PAM=${SELF_HOSTED_PAM:-false}
# use 'curl -v' and 'set -x' for verbose debugging 
CURL="curl -sk"
util_defaults="set -u"

showUsage() {
  echo "Usage:"
  echo "  System Info:"
  echo "    $0 cpms_get"
  echo
  echo "  Platform commands:"
  echo "    $0 platform_details <platform-name>"
  echo "    $0 platform_export <platform-name> <output-filename>"
  echo "    $0 platform_import <zipfile-name>"
  echo "    $0 platform_target_delete <target-platform-name>"
  echo "    $0 platform_groups_get"
  echo "    $0 platform_rotational_groups_get"
  echo
  echo "  Safe commands:"
  echo "    $0 safes_get"
  echo "    $0 safe_get <safe-name>"
  echo "    $0 safe_accounts_get <safe-name>"
  echo "    $0 safe_create <safe-name> <description> [ <cpm-name> ]"
  echo "    $0 safe_delete <safe-name>"
  echo "    $0 safe_member_get <safe-name> <member-name>"
  echo "    $0 safe_admin_add <safe-name> <member-name>"
  echo "    $0 safe_member_delete <safe-name> <member-name>"
  echo
  echo "  Safe Account Group commands:"
  echo "    $0 safe_groups_get <safe-name>"
  echo "    $0 safe_group_create <safe-name> <group-name> <group-platform-name>"
  echo "    $0 safe_group_member_add <numeric-group-id> <numeric-account-id>"
  echo "    $0 safe_group_members_get <numeric-group-id>"
  echo "    $0 safe_group_member_delete <numeric-group-id> <numeric-account-id>"
  echo
  echo "  Account commands:"
  echo "    $0 account_get <safe-name> <account-name>"
  echo "    $0 account_search <search-string>"
  echo "    $0 account_details_get <numeric-account-id>"
  echo "    $0 account_delete <safe-name> <account-name>"
  echo "    $0 account_create_db_dual <safe-name> <platform-id> <account-name> <username> <password>"
  echo "                      [ <server-address> ] [ <database-name> ] [ <server-port> ]"
  echo "                      [ <virtual-user-name> ] [ <1/2> ] [ <Active/Inactive> ]"
  echo "    $0 account_create_db <safe-name> <platform-id> <account-name> <username> <password>"
  echo "                      [ <server-address> ] [ <database-name> ] [ <server-port> ]"
  echo "    $0 account_create_ssh <safe-name> <platform-id> <account-name> <username> <private-key>"
  echo "                      <server-address>"
  echo "    $0 account_create_aws <safe-name> <platform-id> <account-name> <username> <secret-key>"
  echo "                      <access-key-id> <account-id> [ <region> ] [ <account-alias> ]"
  echo
  echo "  Authn commands:"
  echo "    $0 whoami"
  echo "    $0 auth_token_get - get JWT from CyberArk Identity"
  echo "    $0 session_token_get - get legacy CyberArk Vault session token"
  exit -1

# Commands below are partially implemented and mostly don't work.
# They're here if you want to play with them.
  echo "    $0 safe_member_update <safe-name> <member-name>"
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
    pending_accts_get | onboarding_rules_get | safes_get | platforms_get  | platform_rotational_groups_get | platform_groups_get | cpms_get)
	command=$1
	;;
    platform_details | platform_target_delete)
	if [[ $# != 2 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	platformId="$2"
	;;
    platform_export)
	if [[ $# != 3 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	platformId="$2"
	zipfileName="$3"
	;;
    platform_import)
	if [[ $# != 2 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	zipfileName="$2"
	;;
    safe_get | safe_accounts_get | safe_groups_get | safe_delete)
	if [[ $# != 2 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	safeName=$(urlify "$2")
	;;
    safe_create)
	if [[ $# < 3 && $# > 4 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	safeName="$2"
	description="$3"
	cpmName="$4"
	;;
    safe_member_get | safe_member_add | safe_member_delete | safe_admin_add | safe_member_update)
	if [[ $# != 3 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	safeName=$(urlify "$2")
	memberName="$3"
	;;
    safe_group_members_get)
	if [[ $# != 2 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	groupId=$(urlify "$2")
	;;
    safe_group_create)
	if [[ $# != 4 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	safeName=$(urlify "$2")
	groupName=$(urlify "$3")
	groupPlatformId=$(urlify "$4")
	;;
    safe_group_member_add | safe_group_member_delete)
	if [[ $# != 3 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	groupId=$(urlify "$2")
	accountId=$(urlify "$3")
	;;
    account_details_get)
	if [[ $# != 2 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	accountName=$(urlify "$2")
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
    account_search)
	if [[ $# != 2 ]]; then
	  echo "Incorrect number of arguments."
	  showUsage
	fi
	command=$1
	searchString="$2"
#	searchString=$(urlify "$2")
	;;
    account_create_db_dual)
	if [[ $# != 12 ]]; then
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
	virtualUserName="${10}"
	dualAccountIndex="${11}"
	dualAccountStatus="${12}"
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
    session_token_get)
	command=$1
  	self_hosted_authenticate
	echo $sessionToken
	exit
	;;
    whoami)
        echo "$CYBERARK_ADMIN_USER"
        exit
        ;;
    *)
	echo "Unrecognized command: $1"
	showUsage
	;;
  esac

  if $SELF_HOSTED_PAM; then
    self_hosted_authenticate	# sets global variable authHeader
  else
    pcloud_authenticate		# sets global variable authHeader
  fi

	# invoke function which accesses global variables set above
  echo $($command)
}

#####################################
# sets the global authorization header used in api calls for other methods
function pcloud_authenticate() {
  $util_defaults
#  echo "Authenticating user $CYBERARK_ADMIN_USER..."
  jwToken=$($CURL 							\
        -X POST 							\
        "${CYBERARK_IDENTITY_URL}/oauth2/platformtoken" 			\
        -H "Content-Type: application/x-www-form-urlencoded"      	\
        --data-urlencode "grant_type"="client_credentials"              \
        --data-urlencode "client_id"="$CYBERARK_ADMIN_USER"		\
        --data-urlencode "client_secret"="$CYBERARK_ADMIN_PWD"		\
	| jq -r .access_token)
  authHeader="Authorization: Bearer $jwToken"
}

#####################################
# authenticates to self-hosted vault
function self_hosted_authenticate() {
  $util_defaults
#  echo "Authenticating self-hosted admin: $CYBERARK_ADMIN_USER...""
  sessionToken=$($CURL -X POST 					\
	--header "Content-Type: application/json"		\
	--data "{\"username\":\"$CYBERARK_ADMIN_USER\",	 	\
		\"password\":\"$CYBERARK_ADMIN_PWD\"}"		\
	"${CYBERARK_VAULT_API}/auth/Cyberark/Logon/")
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
        "${CYBERARK_VAULT_API}/DiscoveredAccounts"
  echo
}

#####################################
# https://docs.cyberark.com/PrivCloud-SS/Latest/en/Content/WebServices/GetAutoOnboardingRules.htm
#
function onboarding_rules_get() {
  $util_defaults

  $CURL -X GET                          		\
	-H "$authHeader"				\
        "${CYBERARK_VAULT_API}/AutomaticOnboardingRules"
  echo
}

#####################################
# https://docs.cyberark.com/PrivCloud-SS/Latest/en/Content/WebServices/AddAutomaticOnboardingRule.htm
#
function onboarding_rules_set() {
  $util_defaults

  $CURL -X POST                          		\
	-H "$authHeader"				\
        "${CYBERARK_VAULT_API}/AutomaticOnboardingRules"
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
function cpms_get() {
  $util_defaults
  $CURL 				\
	-X GET				\
	-H "$authHeader"		\
	"${CYBERARK_VAULT_API}/ComponentsMonitoringDetails/CPM"
}

#####################################
function platforms_get() {
  $util_defaults
  $CURL 				\
	-X GET				\
	-H "$authHeader"		\
	"${CYBERARK_VAULT_API}/Platforms"
}

#####################################
function platform_details() {
  $util_defaults
  $CURL 				\
	-X GET				\
	-H "$authHeader"		\
	"${CYBERARK_VAULT_API}/Platforms/$platformId"
}

#####################################
function platform_export() {
  $util_defaults
  $CURL 						\
	-X POST						\
	-H "$authHeader"				\
	-d ""						\
	"${CYBERARK_VAULT_API}/Platforms/$platformId/Export"	\
	> "$zipfileName"
  echo "Platform ID $platformId exported to file $zipfileName in zip format."
}

#####################################
function platform_import() {
  $util_defaults

  importArray=$(base64 -i $zipfileName)
  $CURL -X POST                                      		\
	--header "$authHeader"                          \
        --header "Content-Type: application/json"       \
        "${CYBERARK_VAULT_API}/platforms/import"                \
        --data "{                                       \
        	\"ImportFile\": \"$importArray\"        \
                }"
}

#####################################
function platform_target_delete() {
  $util_defaults
  $CURL -X DELETE			\
	-H "$authHeader"		\
	"${CYBERARK_VAULT_API}/Platforms/Targets/$platformId"
}

#####################################
function platform_groups_get() {
  $util_defaults
  $CURL 				\
	-X GET				\
	-H "$authHeader"		\
	"${CYBERARK_VAULT_API}/platforms/groups"
}

#####################################
function platform_rotational_groups_get() {
  $util_defaults
  $CURL 				\
	-X GET				\
	-H "$authHeader"		\
	"${CYBERARK_VAULT_API}/platforms/rotationalGroups"
}

#####################################
function safes_get() {
  $util_defaults
  $CURL 				\
	-X GET				\
	-H "$authHeader"		\
	"${CYBERARK_VAULT_API}/Safes"
}

#####################################
function safe_get() {
  $util_defaults
  printf -v query '.value[] | select(.safeName=="%s")' $safeName
  echo $(safes_get) | jq "$query"
}

#####################################
function safe_accounts_get() {
  $util_defaults
  filter=$(urlify "filter=safeName eq ${safeName}")
  $CURL 				\
	-X GET				\
	-H "$authHeader"		\
	"${CYBERARK_VAULT_API}/Accounts?$filter"
}

#####################################
all_safe_options_for_reference(){
  "numberOfDaysRetention": 7,
  "numberOfVersionsRetention": null,
  "oLACEnabled": true,
  "autoPurgeEnabled": true,
  "managingCPM": "passwordManager",
  "safeName": "PasswordManagerSafe",
  "description": "This is PasswordManager safe.",
  "location": ""
}
function safe_create() {
  $util_defaults

  # cpmName is optional
  if [[ "$cpmName" != "" ]]; then
    printf -v cpmKeyValue '\"managingCPM\": \"%s\", \' $cpmName
  else
    cpmKeyValue=" "
  fi

  response=$($CURL 					\
	-X POST						\
	--write-out '\n%{http_code}'			\
        -H 'Content-Type: application/json'		\
	-H "$authHeader"				\
	"${CYBERARK_VAULT_API}/Safes"				\
	-d "{						\
		\"SafeName\":\"$safeName\",		\
		\"NumberOfDaysRetention\":0,		\
		$cpmKeyValue				\
		\"Description\":\"$description\"	\
	    }")

  http_code=$(tail -n1 <<< "$response")  # get http_code on last line
  content=$(sed '$ d' <<< "$response")   # trim http_code

  case $http_code in
    201)
        echo "Safe $safeName created."
       ;;
    400)
        echo "$0:safe_create()"
        echo "  Unable to create safe $safeName."
	echo
	echo "$content"
        ;;
    403)
        echo "$0:safe_create()"
        echo "  Unable to create safe $safeName."
        echo "  Check user $CYBERARK_ADMIN_USER is has sufficient permissions."
	echo
	echo "$content"
        exit -1
        ;;
    *)
        echo "$0:safe_create(): Unknown return code: $http_code"
	echo
	echo "$content"
        exit -1
        ;;
  esac

}

#####################################
function safe_delete() {
  $util_defaults
  $CURL 				\
	-X DELETE			\
	-H "$authHeader"		\
	"${CYBERARK_VAULT_API}/Safes/$safeName"
}

#####################################
function safe_member_get() {
  $util_defaults
  $CURL 				\
	-X GET				\
	-H "$authHeader"		\
	"${CYBERARK_VAULT_API}/Safes/${safeName}/members/${memberName}/"
}

#####################################
function safe_member_add() {
  $util_defaults
        $CURL -s \
          --request POST                                        \
	  -H "$authHeader"		\
          --header 'Content-Type: application/json'             \
          ${CYBERARK_VAULT_API}/Safes/${safeName}/Members/ 		\
          --data "{                                             \
                \"memberName\":\"$memberName\",                 \
                \"memberType\":\"User\",                        \
                \"permissions\": {                              \
                        \"useAccounts\":true,                   \
                        \"retrieveAccounts\": true,             \
                        \"listAccounts\": true,                 \
                        \"accessWithoutConfirmation\": true     \
                        }                                       \
                }"
}

#####################################
function safe_admin_add() {
  $util_defaults
        $CURL -s \
          --request POST                                        \
	  -H "$authHeader"					\
          -H 'Content-Type: application/json'             	\
          ${CYBERARK_VAULT_API}/Safes/${safeName}/Members/ 		\
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
function safe_member_update() {
  $util_defaults
  $CURL 								\
	-X PUT								\
	-H "$authHeader"						\
	"${CYBERARK_VAULT_API}/Safes/${safeName}/members/${memberName}/"	\
	-d "{								\
		\"isReadOnly\" : \"false\",				\
                \"permissions\": {                              	\
                        \"accessWithoutConfirmation\": true		\
		}							\
	   }"
}

#####################################
function safe_member_delete() {
  $util_defaults
  $CURL 				\
	-X DELETE			\
	-H "$authHeader"		\
	"${CYBERARK_VAULT_API}/Safes/$safeName/Members/${memberName}/"
}

#####################################
function safe_groups_get() {
  $util_defaults
  $CURL 				\
	-X GET				\
	-H "$authHeader"		\
	"${CYBERARK_VAULT_API}/AccountGroups?Safe=$safeName"
}

#####################################
function safe_group_create() {
  $util_defaults

  response=$($CURL 					\
	-X POST						\
	--write-out '\n%{http_code}'			\
        -H 'Content-Type: application/json'		\
	-H "$authHeader"				\
	"${CYBERARK_VAULT_API}/AccountGroups"			\
	-d "{						\
		\"Safe\":\"$safeName\",			\
		\"GroupName\": \"$groupName\",			\
		\"GroupPlatformId\":\"$groupPlatformId\"	\
	    }")

  http_code=$(tail -n1 <<< "$response")  # get http_code on last line
  content=$(sed '$ d' <<< "$response")   # trim http_code

  case $http_code in
    201)
        echo "Group $groupName created in safe $safeName."
       ;;
    400)
        echo "$0:safe_group_create()"
        echo "  Unable to create group $groupName in safe $safeName."
	echo
	echo "$content"
        ;;
    403)
        echo "$0:safe_group_create()"
        echo "  Unable to create group $groupName in safe $safeName."
        echo "  Check user $CYBERARK_ADMIN_USER is has sufficient permissions."
	echo
	echo "$content"
        exit -1
        ;;
    *)
        echo "$0:safe_group_create(): Unknown return code: $http_code"
	echo
	echo "$content"
        exit -1
        ;;
  esac

}

#####################################
function safe_group_member_add() {
  $util_defaults
  $CURL 				\
	-X POST				\
	-H "$authHeader"		\
	-H "Content-Type: application/json"		\
	"${CYBERARK_VAULT_API}/AccountGroups/$groupId/Members"	\
	-d "{						\
		\"AccountID\": \"$accountId\"		\
	   }"
}

#####################################
function safe_group_members_get() {
  $util_defaults
  $CURL 				\
	-X GET				\
	-H "$authHeader"		\
	"${CYBERARK_VAULT_API}/AccountGroups/$groupId/Members"
}

#####################################
function account_details_get {
  $util_defaults
  $CURL 					\
	-X GET					\
	-H "$authHeader"			\
	"${CYBERARK_VAULT_API}/Accounts/$accountName"
}

#####################################
# there does not seem any difference between this output
# and Account Details (GET .../Accounts/{id})
function account_get {
  $util_defaults

  # search example. you can search on everything BUT account name !!?
  #<url>/Accounts?limit=1&searchType=StartsWith&search={{ (instance_username + ' ' + instance_ip) | urlencode }}"

  # So get all accounts in safe and use jq to search on account name
  printf -v query '.value[] | select(.name=="%s")' $accountName
  filter=$(urlify "filter=safeName eq ${safeName}")
  response=$($CURL 				\
	-X GET					\
	-H "$authHeader"			\
	"${CYBERARK_VAULT_API}/Accounts?$filter" 	\
	| jq "$query")

  if [[ "$response" == "" && "$INTERACTIVE" == "true" ]]; then
    echo "Account $accountName not found in safe $safeName."
    exit -1
  fi
  echo $response
}

#####################################
function account_search {
  $util_defaults

  # search example. you can search on everything BUT account name !!?
  #<url>/Accounts?limit=1&search={{ (instance_username + ' ' + instance_ip) | urlencode }}"

  response=$($CURL 				\
	-X GET					\
	-H "$authHeader"			\
	"${CYBERARK_VAULT_API}/Accounts?search=${searchString}")
  echo $response
}

#####################################
function account_delete {
  $util_defaults

  # suppress messages that jq can't parse 
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
    response=$($CURL 			\
	-X DELETE			\
	--write-out '\n%{http_code}'	\
	-H "$authHeader"		\
	"${CYBERARK_VAULT_API_V1}/Accounts/$accountId"
    )
  else
    response=$($CURL 			\
	-X DELETE			\
	--write-out '\n%{http_code}'	\
	-H "$authHeader"		\
	"${CYBERARK_VAULT_API}/Accounts/$accountId"
    )
  fi

  http_code=$(tail -n1 <<< "$response")  # get http_code on last line
  content=$(sed '$ d' <<< "$response")   # trim http_code

  case $http_code in
    200 | 204)
        echo "Deleted account $accountName in safe $safeName."
       ;;
    400)
        echo "$0:account_delete()"
	echo "  Unable to delete account $accountName in safe $safeName."
	echo
	echo "$content"
        ;;
    403)
        echo "$0:account_delete()"
	echo "  Unable to delete account $accountName in safe $safeName."
	echo "  Check user $CYBERARK_ADMIN_USER is a member of the safe and has sufficient permissions."
	echo
	echo "$content"
        exit -1
        ;;
    405)
        echo "Account with ID $accountId does not exist."
	echo
	echo "$content"
        ;;
    *)
        echo "$0:account_delete: Unknown return code: $http_code"
	echo
	echo "$content"
        exit -1
        ;;
  esac
}

#####################################
function account_create_db_dual {
  $util_defaults

  response=$($CURL 					\
	--write-out '\n%{http_code}'			\
	-X POST						\
        -H 'Content-Type: application/json'		\
	-H "$authHeader"				\
	"${CYBERARK_VAULT_API}/Accounts"			\
	-d		"{				\
			  \"platformId\": \"$platformId\",	\
			  \"safeName\": \"$safeName\",		\
			  \"name\": \"$accountName\",		\
			  \"address\": \"$address\",		\
			  \"platformAccountProperties\": {		\
			    \"Port\": \"$dbPort\",			\
			    \"Database\": \"$dbName\",			\
			    \"VirtualUserName\": \"$virtualUserName\",	\
			    \"Index\": \"$dualAccountIndex\",		\
			    \"DualAccountStatus\": \"$dualAccountStatus\",	\
			  },						\
			  \"userName\": \"$username\",			\
			  \"secret\": \"$secret\",			\
			  \"secretType\": \"password\",			\
			  \"secretManagement\": {			\
			    \"automaticManagementEnabled\": true	\
			  }						\
			}"
	)

  http_code=$(tail -n1 <<< "$response")  # get http_code on last line
  content=$(sed '$ d' <<< "$response")   # trim http_code

  case $http_code in
    201)
        echo "Created account $accountName in safe $safeName."
       ;;
    400)
        echo "$0:account_create_db_dual()"
	echo "  Unable to create account $accountName in safe $safeName with platform $platformId."
	echo
	echo "$content"
        ;;
    409)
        echo "Account already exists. Please confirm values in vault are correct."
	echo
	echo "$content"
        ;;
    403)
        echo "$0:account_create_db_dual()"
	echo "  Unable to create account $accountName in safe $safeName."
	echo "  Check user $CYBERARK_ADMIN_USER is a member of the safe and has sufficient permissions."
	echo
	echo "$content"
        exit -1
        ;;
    *)
        echo "$0:account_create_db_dual: Unknown return code: $retCode"
        exit -1
        ;;
  esac
}

#####################################
function account_create_db {
  $util_defaults

  response=$($CURL 					\
	--write-out '\n%{http_code}'			\
	-X POST						\
        -H 'Content-Type: application/json'		\
	-H "$authHeader"				\
	"${CYBERARK_VAULT_API}/Accounts"			\
	-d		"{				\
			  \"platformId\": \"$platformId\",	\
			  \"safeName\": \"$safeName\",		\
			  \"name\": \"$accountName\",		\
			  \"address\": \"$address\",		\
			  \"platformAccountProperties\": {		\
			    \"Port\": \"$dbPort\",			\
			    \"Database\": \"$dbName\"			\
			  },						\
			  \"userName\": \"$username\",			\
			  \"secret\": \"$secret\",			\
			  \"secretType\": \"password\",			\
			  \"secretManagement\": {			\
			    \"automaticManagementEnabled\": true	\
			  }						\
			}"
	)

  http_code=$(tail -n1 <<< "$response")  # get http_code on last line
  content=$(sed '$ d' <<< "$response")   # trim http_code

  case $http_code in
    201)
        echo "Created account $accountName in safe $safeName."
       ;;
    400)
        echo "$0:account_create_db()"
	echo "  Unable to create account $accountName in safe $safeName with platform $platformId."
	echo
	echo "$content"
        ;;
    409)
        echo "Account already exists. Please confirm values in vault are correct."
	echo
	echo "$content"
        ;;
    403)
        echo "$0:account_create_db()"
	echo "  Unable to create account $accountName in safe $safeName."
	echo "  Check user $CYBERARK_ADMIN_USER is a member of the safe and has sufficient permissions."
	echo
	echo "$content"
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

  response=$($CURL 					\
	-X POST						\
	--write-out '\n%{http_code}'			\
        -H 'Content-Type: application/json'		\
	-H "$authHeader"				\
	"${CYBERARK_VAULT_API}/Accounts"			\
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

  http_code=$(tail -n1 <<< "$response")  # get http_code on last line
  content=$(sed '$ d' <<< "$response")   # trim http_code

  case $http_code in
    201)
        echo "Created account $accountName in safe $safeName."
       ;;
    400)
        echo "$0:account_create_ssh()"
	echo "  Unable to create account $accountName in safe $safeName with platform $platformId."
	echo "  Check if requested platform $platformId is activated in the vault."
	echo
	echo "$content"
        ;;
    409)
        echo "Account already exists. Please confirm values in vault are correct."
	echo
	echo "$content"
        ;;
    403)
        echo "$0:account_create_ssh()"
	echo "  Unable to create account $accountName in safe $safeName."
	echo "  Check user $CYBERARK_ADMIN_USER is a member of the safe and has sufficient permissions."
	echo
	echo "$content"
        exit -1
        ;;
    *)
        echo "$0:account_create_ssh: Unknown return code: $http_code"
	echo
	echo "$content"
        exit -1
        ;;
  esac
}

#####################################
function account_create_aws {
  $util_defaults

  response=$($CURL 					\
	-X POST						\
	--write-out '\n%{http_code}'			\
        -H 'Content-Type: application/json'		\
	-H "$authHeader"				\
	"${CYBERARK_VAULT_API}/Accounts"			\
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

  http_code=$(tail -n1 <<< "$response")  # get http_code on last line
  content=$(sed '$ d' <<< "$response")   # trim http_code

  case $http_code in
    201)
        echo "Created account $accountName in safe $safeName."
       ;;
    400)
        echo "$0:account_create_aws()"
	echo "  Unable to create account $accountName in safe $safeName with platform $platformId."
	echo "  Check if requested platform $platformId is activated in the vault."
	echo
	echo "$content"
        ;;
    409)
        echo "Account already exists. Please confirm values in vault are correct."
	echo
	echo "$content"
        ;;
    403)
        echo "$0:account_create_aws()"
	echo "  Unable to create account $accountName in safe $safeName."
	echo "  Check user $CYBERARK_ADMIN_USER is a member of the safe and has sufficient permissions."
	echo
	echo "$content"
        exit -1
        ;;
    *)
        echo "$0:account_create_aws: Unknown return code: $http_code"
	echo
	echo "$content"
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
  if [[ "$CYBERARK_IDENTITY_URL" == "" ]]; then
    echo
    echo "  CYBERARK_IDENTITY_URL must be set."
    all_env_set=false
  fi
  if [[ "$CYBERARK_VAULT_API" == "" ]]; then
    echo
    echo "  CYBERARK_VAULT_API must be set - e.g. 'https://my-secrets.privilegecloud.cyberark.cloud/api'"
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
