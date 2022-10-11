#!/bin/bash

main() {
  curl --cacert $MTLS_CA_CHAIN --cert $MTLS_CERT --key $MTLS_PRIVATE_KEY https://$SERVER_CN
#  echo_all
}

echo_all() {
  echo
  echo "MTLS_CA_CHAIN:"; openssl x509 -in $MTLS_CA_CHAIN -text -nocert
  echo
  echo
  echo "MTLS_CERT:"; openssl x509 -in $MTLS_CERT -text -nocert
  echo
  echo
  echo "MTLS_PRIVATE_KEY:"; openssl pkey -in $MTLS_PRIVATE_KEY -text -noout
  echo
}

main "$@"
