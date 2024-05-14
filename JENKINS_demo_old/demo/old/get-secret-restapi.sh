#!/bin/bash 

# global variables
declare ADMIN_SESSION_TOKEN
declare HOST_API_KEY
declare HOST_SESSION_TOKEN
declare SECRET_VALUE
declare URLIFIED

################  MAIN   ################
# $1 - name of input file containing host name, API key and name of variable to read

main() {

	if [ "$CONJUR_AUTHN_LOGIN" == "" ]; then
		printf "source auth.env first...\n\n"
		exit -1
	fi

#	clear
	printf "\n\nHost name: %s\n" $CONJUR_AUTHN_LOGIN
	printf "API key: %s \n" $CONJUR_AUTHN_API_KEY
	printf "Var Uname: %s \n" $VAR_UNAME
	printf "Var Pname: %s \n\n" $VAR_PNAME
	read -n 1 -s -p "Press any key to continue"
	echo

	host_authn $CONJUR_AUTHN_LOGIN $CONJUR_AUTHN_API_KEY  		# sets HOST_SESSION_TOKEN value
	fetch_secret $VAR_UNAME
	echo "Value for $VAR_UNAME is:" $SECRET_VALUE
	
	fetch_secret $VAR_PNAME
	echo "Value for $VAR_PNAME is:" $SECRET_VALUE

	echo
	echo
	echo

}


################
# HOST AUTHN using its name and API key to get session token
# $1 - host name 
# $2 - API key
host_authn() {
	local host_name=$1; shift
	local host_api_key=$1; shift

	urlify $host_name
	local host_name_urlfmt=$URLIFIED		# authn requires host/ prefix

	# Authenticate host w/ its name & API key to get session token
	 response=$(curl -s \
	 --cacert $CONJUR_CERT_FILE \
	 --request POST \
	 --data-binary $host_api_key \
	 $CONJUR_APPLIANCE_URL/authn/users/{$host_name_urlfmt}/authenticate)
	 HOST_SESSION_TOKEN=$(echo -n $response| base64 | tr -d '\r\n')
}

################
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

################
# FETCH SECRET using session token
# $1 - name of secret to fetch
fetch_secret() {
	local var_id=$1; shift

	urlify $var_id
	local var_id_urlfmt=$URLIFIED

	# FETCH variable value
	SECRET_VALUE=$(curl -s \
	 --cacert $CONJUR_CERT_FILE \
         --request GET \
         -H "Content-Type: application/json" \
         -H "Authorization: Token token=\"$HOST_SESSION_TOKEN\"" \
         $CONJUR_APPLIANCE_URL/variables/{$var_id_urlfmt}/value)

}

main "$@"
