#!/bin/bash
#set -e

source ../env/pkiaas.env
source ../env/sandbox.env
source ../bashlib/conjur_utils.sh
source ../bashlib/pkiaas_lib.sh

export CONJUR_AUTHN_LOGIN="host/pki-admin"
export CONJUR_AUTHN_API_KEY="${CONJUR_PKI_ADMIN_API_KEY}"

export PKI_VERBOSE=""
export PKI_TRACE=true

main() {
  conjur_access_token=$(conjur_authenticate)
  export conjur_access_token="$conjur_access_token"

  metaUnitTests
  caUnitTests
  templateUnitTests
  certificateUnitTests
  crlPurgeUnitTests
  workflowTests
}

###########################
function metaUnitTests() {
  echo
  echo
  echo "##################################################"
  echo "                  META UNIT TESTS"
  echo "##################################################"
  echo

  PKI.index
  PKI.health
}

###########################
function caUnitTests() {
  echo
  echo
  echo "##################################################"
  echo "                   CA UNIT TESTS"
  echo "##################################################"

  echo $(PKI.generateSelfSignedCA "cyberark.ca.local" 525600) | jq
  return

  # below functions not fully implemented
  echo $(PKI.setCA) | jq
  PKI.getCA				# returns just the cert - no json
  echo $(PKI.generateIntCSR "cyberark.intermediate.local") | jq
  echo $(PKI.sign)
  echo $(PKI.setCAChain) | jq
  echo $(PKI.getCAChain) | jq
}

###########################
function templateUnitTests() {
  echo
  echo
  echo "##################################################"
  echo "              TEMPLATE UNIT TESTS"
  # To do:
  # "ManageTemplate", "Put", "/template/manage"
  echo "##################################################"
  echo

  local templateName="newTemplateName";
  local maxTTL=525600

  echo $(PKI.listTemplates) | jq
  PKI.createTemplate "$templateName" $maxTTL
  echo $(PKI.listTemplates) | jq
  echo $(PKI.getTemplate "$templateName") | jq
  PKI.deleteTemplate "$templateName"
  echo $(PKI.listTemplates) | jq
}

###########################
function certificateUnitTests() {
  echo
  echo
  echo "##################################################"
  echo "             CERTIFICATE UNIT TESTS"
  echo "##################################################"
  echo

  local templateName="certCreateTemplate"
  local certCN="WIN-206D32OIKB7"
  local maxTTL=525600
  local ttl=3600

  ############
  # UNHAPPY PATH - all should fail
  # try to create cert w/ non-existent template
  $(PKI.createCertificate "template-no-bueno" "$certCN" $ttl)

  ############
  # HAPPY PATH - all should succeed
  echo $(PKI.listCertificates) | jq
  PKI.createTemplate "$templateName" $maxTTL
  echo $(PKI.getTemplate "$templateName") | jq
  create_response=$(PKI.createCertificate "$templateName" "$certCN" $ttl)
  echo $create_response | jq 
  certificateCreated=$(echo "$create_response" | jq -r .certificate)
  serialNumber=$(echo "$create_response" | jq -r .serialNumber)

  get_response=$(PKI.getCertificate "$serialNumber")
  echo $get_response | jq
  certificateGotten=$(echo "$get_response" | jq -r .certificate)
  if [ "${certificateCreated}" != "${certificateGotten}" ]; then
    echo "ERROR: Certificates should match but do not!"
    return 1
  fi

  PKI.revokeCertificate "$serialNumber"
  PKI.deleteTemplate "certCreateTemplate"
  echo $(PKI.listTemplates) | jq
}

###########################
function crlPurgeUnitTests() {
  echo
  echo
  echo "##################################################"
  echo "            CRL and PURGE UNIT TESTS"
  # To do:
  # "PurgeCRL", "Post", "/crl/purge"
  echo "##################################################"
  echo

  echo $(PKI.getCRL) | jq
  echo $(PKI.purge) | jq
}

###########################
function workflowTests() {
  echo
  echo
  echo "##################################################"
  echo "                WORKFLOW TESTS"
  echo "##################################################"
  echo

  revokeAllCertificates
  echo $(PKI.purge) | jq
  echo $(PKI.listCertificates) | jq
}

###########################
function revokeAllCertificates() {
  local response;

  >&2 echo "#########################"
  >&2 echo "Test: Revoke all certificates"
  response=$(PKI.listCertificates)
  for serialNumber in $(echo "${response}" | jq '.["certificates"]' | jq -r -c '.[]'); do
        response=$(PKI.revokeCertificate "$serialNumber")
        >&2 echo "revoked $serialNumber and response was $response"
  done
  echo 0        # successful exit code as response
}

main "$@"
