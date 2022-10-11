#!/bin/bash

source ../../config/conjur.config
source ../env/pkiaas.env
source ../env/sandbox.env	# Conjur & PKI service vars
source ./env/mtls-demo.config	# demo variables

source ../bashlib/pkiaas_lib.sh		# bashlib of PKIaaS functions
source ../bashlib/conjur_utils.sh	# bashlib of conjur CLI utilities

#export PKI_VERBOSE="-v"	# uncomment for REST call debugging
#export PKI_TRACE=true		# uncomment to trace certificate generation

main() {

  case $1 in

    init)
	# load policies as Conjur admin user - policies are owned by PKI admin user
	export CONJUR_AUTHN_LOGIN="admin"
	export CONJUR_AUTHN_API_KEY="${CONJUR_ADMIN_PASSWORD}"
	echo "Loading demo policy..."
	conjur_append_policy root ./policy/mutual_tls.yml

	# authenticate as PKI admin user
	export CONJUR_AUTHN_LOGIN="${CONJUR_PKI_ADMIN}"
	export CONJUR_AUTHN_API_KEY="${CONJUR_PKI_ADMIN_API_KEY}"
	conjur_access_token=$(conjur_authenticate)
	export conjur_access_token="$conjur_access_token"

	echo "Generating self-signed intermediate CA..."
	response=$(PKI.generateSelfSignedCA "$CA_CN")
	if $PKI_TRACE; then echo "$response" | jq ; fi
	response="$(PKI.getCA)"
	if $PKI_TRACE; then echo "$response" | openssl x509 -text -noout; fi

	echo "Creating certificate template..."
	response=$(PKI.createTemplate "$TEMPLATE_NAME" $MAX_CERT_TTL)
	if $PKI_TRACE; then echo "$response" | jq ; fi
	response=$(PKI.getTemplate "$TEMPLATE_NAME")
	if $PKI_TRACE; then echo "$response" | jq ; fi

	create_client_cert
	create_server_cert
	;;

    client) 
	# authenticate as PKI admin user
	export CONJUR_AUTHN_LOGIN="${CONJUR_PKI_ADMIN}"
	export CONJUR_AUTHN_API_KEY="${CONJUR_PKI_ADMIN_API_KEY}"
	conjur_access_token=$(conjur_authenticate)
	export conjur_access_token="$conjur_access_token"

	create_client_cert
	;;
    server)
	# authenticate as PKI admin user
	export CONJUR_AUTHN_LOGIN="${CONJUR_PKI_ADMIN}"
	export CONJUR_AUTHN_API_KEY="${CONJUR_PKI_ADMIN_API_KEY}"
	conjur_access_token=$(conjur_authenticate)
	export conjur_access_token="$conjur_access_token"

	create_server_cert
	;;
    *)
	echo "Usage: $0 [ init | client | server ]"
	exit -1
	;;
  esac
}

#############################
function create_client_cert() {
  echo "Creating client certificate & storing in Conjur..."
  response=$(PKI.createCertificate "$TEMPLATE_NAME" "$CLIENT_CN" $CLIENT_CERT_TTL)
  if $PKI_TRACE; then echo "$response" | jq ; fi
  conjur_set_variable mutual-tls/client/certificate "$(echo $response | jq -r .certificate)"
  conjur_set_variable mutual-tls/client/privateKey "$(echo $response | jq -r .privateKey)"
  conjur_set_variable mutual-tls/client/caCertificate "$(echo $response | jq -r .caCertificate)"
}

#############################
function create_server_cert() {
  echo "Creating server certificate & storing in build directory..."
  response=$(PKI.createCertificate "$TEMPLATE_NAME" "$SERVER_CN" $SERVER_CERT_TTL)
  if $PKI_TRACE; then echo "$response" | jq ; fi
  conjur_set_variable mutual-tls/server/certificate "$(echo $response | jq -r .certificate)"
  conjur_set_variable mutual-tls/server/privateKey "$(echo $response | jq -r .privateKey)"
  conjur_set_variable mutual-tls/server/caCertificate "$(echo $response | jq -r .caCertificate)"

  # add certs & key to build directory for image build
  echo "$(echo $response | jq -r .certificate)" > ./build/server/tls-cert
  echo "$(echo $response | jq -r .privateKey)" > ./build/server/tls-private-key
  echo "$(echo $response | jq -r .caCertificate)" > ./build/server/tls-ca-chain
}

main "$@"
