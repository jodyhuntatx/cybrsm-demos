#!/bin/bash  

#CONJUR_APPLIANCE_URL=https://jenkins/api
#CONJUR_CERT_FILE=/var/jenkins_home/conjur-dev.pem

declare DEBUG_BREAKPT=""
#declare DEBUG_BREAKPT="read -n 1 -s -p 'Press any key to continue'"

################  MAIN   ################

main() {
	if [[ $# -ne 4 ]] ; then
		printf "\n\tUsage: %s <hf-token> <jenkins-hostname> <conjur-url> <conjur-cert-file>\n\n" $0
		exit 1
	fi
	local hf_token=$1; shift
	local host_name=$1; shift
	CONJUR_APPLIANCE_URL=$1; shift
	CONJUR_CERT_FILE=$1; shift

	hf_host_create $hf_token $host_name 	# NOTE hostname not in URL format - sets HOST_API_KEY global value

	if [[ ("$HOST_API_KEY" == "") || ($HOST_API_KEY == null) ]]; then
		printf "\n\nAPI key not generated. Perhaps host factory token has expired. Please regenerate...\n\n"
		exit 1
	fi

	host_authn $host_name $HOST_API_KEY  		# sets HOST_SESSION_TOKEN value

	echo $HOST_SESSION_TOKEN
}

################
# HF HOST CREATE to add host w/ hostname to the layer associated with the host factory token 
#    Note that if the host already exists, this command will create a new API key for it 
# $1 - application name

hf_host_create() {
	local hf_token=$1; shift
	local host_name=$1; shift

	HOST_API_KEY=$(curl \
	 -s \
	 --cacert $CONJUR_CERT_FILE \
	 --request POST \
     	 -H "Content-Type: application/json" \
	 -H "Authorization: Token token=\"$hf_token\"" \
	 $CONJUR_APPLIANCE_URL/host_factories/hosts?id=$host_name \
	 | jq -r '.api_key')
}

################
# HOST AUTHN using its name and API key to get session token
# $1 - host name 
# $2 - API key
host_authn() {
	local host_name=$1; shift
	local host_api_key=$1; shift

	urlify $host_name
	local host_name_urlfmt=host%2F$URLIFIED		# authn requires host/ prefix

	# Authenticate host w/ its name & API key to get session token
	 response=$(curl -s \
	 --cacert $CONJUR_CERT_FILE \
	 --request POST \
	 --data-binary $host_api_key \
	 $CONJUR_APPLIANCE_URL/authn/users/{$host_name_urlfmt}/authenticate)
	 HOST_SESSION_TOKEN=$(echo -n $response| base64 | tr -d '\r\n')
}

# URLIFY - converts '/' and ':' in input string to hex equivalents
# in: $1 - string to convert
# out: URLIFIED - converted string in global variable
urlify() {
        local str=$1; shift
        str=$(echo $str | sed 's= =%20=g')
        str=$(echo $str | sed 's=/=%2F=g')
        str=$(echo $str | sed 's=:=%3A=g')
        URLIFIED=$str
}

main "$@"
