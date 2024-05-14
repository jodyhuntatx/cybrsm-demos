#!/bin/bash

conjurUrl=https://cybr-secrets.secretsmgr.cyberark.cloud/api
varName=data/vault/gitlab-cybrlab-conjur-cloud/system-user/password
jwToken="$(./cybrid-cli.sh token)"

main() {
  var=$(urlify $varName)
  authToken=$(curl -sk 						\
  	$conjurUrl/authn-jwt/cybrid/conjur/authenticate		\
        -H 'Content-Type: application/x-www-form-urlencoded'    \
        -H "Accept-Encoding: base64"                            \
        --data-urlencode "jwt=$jwToken"				\
  )
  curl -sk 						\
	$conjurUrl/secrets/conjur/variable/$var		\
        --request GET 					\
        -H "Content-Type: application/json"		\
        -H "Authorization: Token token=\"$authToken\""
}

################
# URLIFY - urlencodes input string
# in: $1 - string to convert
# out: urlencoded string
urlify() {
        local str=$1; shift
        str=$(echo $str | sed 's= =%20=g')
        str=$(echo $str | sed 's=/=%2F=g')
        str=$(echo $str | sed 's=:=%3A=g')
        echo $str
}

main "$@"
