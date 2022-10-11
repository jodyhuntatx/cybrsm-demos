#! /bin/bash -e

#CONJUR_APPLIANCE_URL=https://jenkins/api
#CONJUR_CERT_FILE=/var/jenkins_home/conjur-dev.pem

main() {
	if [[ $# -ne 4 ]]; then
		printf "\n\tUsage: %s <access-token> <var-name> <conjur-url> <conjur-cert>\n\n" $0
		exit -1
	fi

	local auth_token=$1; shift
	local var_name=$1; shift
	CONJUR_APPLIANCE_URL=$1; shift
	CONJUR_CERT_FILE=$1; shift

	urlify $var_name
	var_name=$URLIFIED
	
	local var_value=$(curl -s \
		--cacert $CONJUR_CERT_FILE \
		--request GET \
		-H "Authorization: Token token=\"$auth_token\"" \
		$CONJUR_APPLIANCE_URL/variables/$var_name/value)
	echo $var_value
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
					
main $@
