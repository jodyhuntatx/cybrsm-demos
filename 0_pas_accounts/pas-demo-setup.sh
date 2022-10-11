#!/bin/bash
source ./pas-demo-setup.config

SAFE=foo

main() {
  $CYBR login -i --non-interactive -a cyberark -b $PAS_PVWA_URL -u $PAS_ADMIN_NAME 

  create_safe PetClinicTest
  sleep 3
  add_safe_member PetClinicTest Administrator "$ACL_FULL_ADMIN"
  sleep 3
  add_safe_account Database PetClinicTest MySQL test_user1 password UHGMLk1 MySQL 
  create_safe PetClinicDev
  sleep 3
  add_safe_member PetClinicDev Administrator "$ACL_FULL_ADMIN"
  sleep 3
  add_safe_account Database PetClinicDev MySQL dev_user1 password Cyberark1 MySQL 
}

############################
create_safe() {
  if [[ $# != 1 ]]; then echo "Usage: $0 <safe-name>"; exit -1; fi
  safeName=$1
  $CYBR safes add -s $safeName --days 0 --cpm $PAS_CPM_NAME	\
	--desc "created with cybr cli"
}

############################
add_safe_member() {
  if [[ $# != 3 ]]; then echo "Usage: $0 <safe-name> <member-name> <acl>"; exit -1; fi
  safeName=$1
  memberName=$2
  acl="$3"
  $CYBR safes add-member -s $safeName --member-name $memberName $acl 2>1 /dev/null
}

############################
add_safe_account() {
  if [[ $# < 7 ]]; then echo "Usage: $0 <system-type> <safe-name> <account-name> <user-name> <secret-type> <secret-value> <platform-id> [ <address> [ <port} ] ]"; exit -1; fi
  systemType=$1
  safeName=$2
  accountName=$3
  userName=$4
  secretType=$5
  secretValue=$6
  platformId=$7
  address=""
  port=""
  if [[ $# > 7 ]]; then
    address="-a $8"
  fi
  if [[ $# > 8 ]]; then
    port="-e \"port=$9\""
  fi
  $CYBR accounts add 			\
		-s $safeName		\
		-n $accountName		\
		-p $platformId		\
		-u $userName		\
		-t $secretType		\
		-c $secretValue		\
		$address		\
		$port
}

main "$@"
