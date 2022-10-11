##################################################
#               PKIAAS BASH LIBRARY
##################################################
#
# >>> BUG LOG <<<
# /ca/generate/selfsigned - keyBits input value must be string or generates HTTP 400
# /template/create - keyBits input value must be string or generates HTTP 400

PKI_VERBOSE=${PKI_VERBOSE:-""}		# sets PKI_VERBOSE to empty string if undefined
PKI_TRACE=${PKI_TRACE:-false}		# sets PKI_TRACE to false if undefined

##################################
function trace() {
  if [[ $# != 1 ]]; then echo "Usage: ${FUNCNAME}(msg)"; return; fi
  local msg=$1; shift
  if $PKI_TRACE; then
    >&2 echo "$msg"
  fi
}

##################################
function error() {
  if [[ $# != 1 ]]; then echo "Usage: ${FUNCNAME}(msg)"; return; fi
  local msg=$1; shift
  >&2 echo "   >>>> ERROR: $msg"
}

##################################################
#                META FUNCTIONS
##################################################

##################################
function PKI.index() {
  trace "#########################"
  trace "Index, GET, /"
  curl -s \
    $PKI_VERBOSE \
    $PKI_URL/
  trace ""
}

##################################
function PKI.health() {
  trace "#########################"
  trace "Health, Get, /health"
  curl -s \
    $PKI_VERBOSE \
    $PKI_URL/health
}

##################################################
#                SET/GET CA FUNCTIONS
##################################################

##################################
# IMPLEMENTATION NOT YET VERIFIED
function PKI.setCA() {
  if [[ $# != 1 ]]; then echo "Usage: ${FUNCNAME}(rootCA)"; return; fi
  local response;

  trace "#########################"
  trace "SetIntermediateCertificate, Post, /ca/set"
  data=$(echo "{ \"commonName\": \"$commonName\", \"keyAlgo\": \"RSA\", \"keyBits\": 2048 }")
  response=$(curl --fail -s \
    -H "Content-Type: application/json" \
    -H "$conjur_access_token" \
    --data "$data" \
    $PKI_VERBOSE \
    $PKI_URL/ca/set)
  if [[ "$response" == "" ]]; then error "${FUNCNAME}"; fi
  echo $response
}

##################################
function PKI.getCA() {
  local response;

  trace "#########################"
  trace "GetCA, Get, /ca/certificate"
  response=$(curl --fail -s \
    -H "$conjur_access_token" \
    $PKI_VERBOSE \
    $PKI_URL/ca/certificate)
  echo "$response"
}

##################################################
#         SELF-SIGNED INTERMEDIATE CA 
##################################################

##################################
function PKI.generateSelfSignedCA() {
  if [[ $# != 2 ]]; then echo "Usage: ${FUNCNAME}(commonName,maxTTL)"; return; fi
  local commonName=$1; shift
  local maxTTL=$1; shift
  local response;

  trace "#########################"
  trace "GenerateIntermediateCSR, Post, /ca/generate/selfsigned"
  data=$(echo "{ \"commonName\": \"$commonName\", \"keyAlgo\": \"RSA\", \"keyBits\": \"2048\", \"MaxTTL\": $maxTTL }")
  response=$(curl --fail -s \
    -H "Content-Type: application/json" \
    -H "$conjur_access_token" \
    --data "$data" \
    $PKI_VERBOSE \
    $PKI_URL/ca/generate/selfsigned)
  if [[ "$response" == "" ]]; then error "${FUNCNAME}"; fi
  echo $response
}

##################################################
#                ROOT CA FUNCTIONS
##################################################

##################################
# IMPLEMENTATION NOT YET VERIFIED
function PKI.generateIntCSR() {
  if [[ $# != 1 ]]; then echo "Usage: ${FUNCNAME}(commonName)"; return; fi
  local commonName=$1; shift
  local response;

  trace "#########################"
  trace "GenerateIntermediateCSR, Post, /ca/generate"
  data=$(echo "{ \"commonName\": \"$commonName\", \"keyAlgo\": \"RSA\", \"keyBits\": 2048 }")
  response=$(curl --fail -s \
    -H "Content-Type: application/json" \
    -H "$conjur_access_token" \
    --data "$data" \
    $PKI_VERBOSE \
    $PKI_URL/ca/generate)
  if [[ "$response" == "" ]]; then error "${FUNCNAME}"; fi
  echo $response
}

##################################
# IMPLEMENTATION NOT YET VERIFIED
function PKI.signIntCert() {
  if [[ $# != 4 ]]; then echo "Usage: ${FUNCNAME}(csr,commonName,templateName,ttl)"; return; fi
  local csr=$1; shift
  local commonName=$1; shift
  local templateName=$1; shift
  local ttl=$1; shift
  local response;

  trace "#########################"
  trace "SignCertificate, Post, /certificate/sign"
  data=$(echo "{ \"csr\": \"$csr\", \"commonName\": \"$commonName\", \"templateName\": \"$templateName\", \"ttl\": $ttl }")
  response=$(curl --fail -v \
    -H "Content-Type: application/json" \
    -H "$conjur_access_token" \
    --data "$data" \
    $PKI_VERBOSE \
    $PKI_URL/certificate/sign)
  if [[ "$response" == "" ]]; then error "${FUNCNAME}"; fi
  echo $response
}

##################################
# IMPLEMENTATION NOT YET VERIFIED
function PKI.setCAChain() {
  if [[ $# != 1 ]]; then echo "Usage: ${FUNCNAME}(cert)"; return; fi
  local response;

  trace "#########################"
  trace "SetCAChain, Post, /ca/chain/set"
  data=$(echo "{ \"commonName\": \"$commonName\", \"keyAlgo\": \"RSA\", \"keyBits\": 2048 }")
  response=$(curl --fail -s \
    -H "Content-Type: application/json" \
    -H "$conjur_access_token" \
    --data "$data" \
    $PKI_VERBOSE \
    $PKI_URL/ca/chain/set)
  if [[ "$response" == "" ]]; then error "${FUNCNAME}"; fi
  echo $response
}  

##################################
# IMPLEMENTATION NOT YET VERIFIED
function PKI.getCAChain() {
  local response;

  trace "#########################"
  trace "GetCAChain, Get, /ca/chain"
  # TODO CURRENTLY THIS IS RETURNING A 500
  response=$(curl --fail -s \
    $PKI_VERBOSE \
    $PKI_URL/ca/chain)
  echo "$response"
}  

##################################################
#                TEMPLATE FUNCTIONS
##################################################

##################################
function PKI.createTemplate() {
  if [[ $# != 2 ]]; then echo "Usage: ${FUNCNAME}(templateName,maxTTL)"; return; fi
  local templateName=$1; shift
  local maxTTL=$1; shift
  local response;

  trace "#########################"
  trace "CreateTemplate, Post, /template/create {$templateName}"
  data=$(echo "{\"templateName\": \"$templateName\", \"keyAlgo\": \"RSA\", \"keyBits\": \"2048\", \"maxTTL\": $maxTTL }")
  response=$(curl --fail -s \
    -H "Content-Type: application/json" \
    -H "$conjur_access_token" \
    --data "$data" \
    $PKI_VERBOSE \
    $PKI_URL/template/create)
  echo $response	# REST call does not return a response
}

##################################
function PKI.getTemplate() {
  if [[ $# != 1 ]]; then echo "Usage: ${FUNCNAME}(templateName)"; return; fi
  local templateName=$1; shift
  local response;

  trace "#########################"
  trace "GetTemplate, Get, /template/{$templateName}"
  # get a specific template
  response=$(curl --fail -s \
	-H "$conjur_access_token" \
	$PKI_VERBOSE \
	"$PKI_URL/template/$templateName")
  if [[ "$response" == "" ]]; then error "${FUNCNAME}"; fi
  echo $response
}

##################################
function PKI.deleteTemplate() {
  if [[ $# != 1 ]]; then echo "Usage: ${FUNCNAME}(templateName)"; return; fi
  local templateName=$1; shift
  local response;

  trace "#########################"
  trace "DeleteTemplate, Delete, /template/delete/{$templateName}"
  # delete that same template we just examined
  response=$(curl --fail -s \
	-H "$conjur_access_token" \
	-X "DELETE" \
	$PKI_VERBOSE \
	$PKI_URL/template/delete/$templateName)
  echo $response	# REST call does not return a response
}

##################################
function PKI.listTemplates() {
  local response;

  trace "#########################"
  trace "ListTemplates, Get, /templates"
  response=$(curl --fail -s \
	-H "$conjur_access_token" \
  	$PKI_VERBOSE \
	$PKI_URL/templates)
  if [[ "$response" == "" ]]; then error "${FUNCNAME}"; fi
  echo $response
}

##################################################
#              CERTIFICATE FUNCTIONS
##################################################

##################################
function PKI.createCertificate() {
  if [[ $# != 3 ]]; then echo "Usage: ${FUNCNAME}(templateName,commonName,ttl)"; return; fi
  local templateName=$1; shift
  local commonName=$1; shift
  local ttl=$1; shift
  local response;

  trace "#########################"
  trace "CreateCertificate, Post, /certificate/create {$templateName} {$commonName}"
  data=$(echo "{\"templateName\": \"$templateName\",\"commonName\": \"$commonName\",\"ttl\": $ttl }")
  response=$(curl --fail -s \
    -H "Content-Type: application/json" \
    -H "$conjur_access_token" \
    --data "$data" \
    $PKI_VERBOSE \
    $PKI_URL/certificate/create)
  if [[ "$response" == "" ]]; then error "${FUNCNAME}"; fi
  echo $response
}

##################################
function PKI.getCertificate() {
  if [[ $# != 1 ]]; then echo "Usage: ${FUNCNAME}(certSerialNumber)"; return; fi
  local serialNumber=$1; shift
  local response;

  trace "#########################"
  trace "GetCertificate, Get, /certificate/{$serialNumber}"
  response=$(curl --fail -s \
    -H "Content-Type: application/json" \
    -H "$conjur_access_token" \
    $PKI_VERBOSE \
    $PKI_URL/certificate/$serialNumber)
  if [[ "$response" == "" ]]; then error "${FUNCNAME}"; fi
  echo $response
}

##################################
function PKI.revokeCertificate() {
  if [[ $# != 1 ]]; then echo "Usage: ${FUNCNAME}(certSerialNumber)"; return; fi
  local serialNumber=$1; shift
  local response;

  trace "#########################"
  trace "RevokeCertificate, Post, /certificate/revoke {$serialNumber}"
  data=$(echo "{ \"serialNumber\": \"$serialNumber\" }")
  response=$(curl --fail -s \
    -H "Content-Type: application/json" \
    -X POST \
    --data "$data" \
    -H "$conjur_access_token" \
    $PKI_VERBOSE \
    $PKI_URL/certificate/revoke)
  echo $response	# REST call does not return a response
}

##################################
function PKI.listCertificates() {
  local response;

  trace "#########################"
  trace "ListCertificates, Get, /certificates"
  response=$(curl --fail -s \
    -H "Content-Type: application/json" \
    -H "$conjur_access_token" \
    $PKI_VERBOSE \
    $PKI_URL/certificates)
  if [[ "$response" == "" ]]; then error "${FUNCNAME}"; fi
  echo $response
}

##################################################
#             CRL and PURGE FUNCTIONS
##################################################

##################################
# IMPLEMENTATION NOT YET VERIFIED
function PKI.getCRL() {
  local response;

  trace "#########################"
  trace "GetCRL, Get, /crl"
  response=$(curl --fail -s \
    -H "Content-Type: application/json" \
    -H "$conjur_access_token" \
    $PKI_VERBOSE \
    $PKI_URL/crl)
  if [[ "$response" == "" ]]; then error "${FUNCNAME}"; fi
  echo $response
}

##################################
# IMPLEMENTATION NOT YET VERIFIED
function PKI.purge() {
  local response;

  trace "#########################"
  trace "Purge, Post, /purge"
  response=$(curl --fail -s \
    -H "Content-Type: application/json" \
    -X POST \
    -H "$conjur_access_token" \
    $PKI_VERBOSE \
    $PKI_URL/purge)
  echo $response	# REST call does not return a response
}

##################################################
#             END PKIAAS LIBRARY
##################################################

