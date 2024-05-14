##########################################
## Conjur_Cloud_Vars
##
# Platform tenant id
export IDENTITY_TENANT_ID="aaw4398"

# Admin service account user
export CONJUR_ADMIN_USER="conjur_bot@altairpd.com"
export CONJUR_ADMIN_PWD="$(keyring get cybrid jodybotpwd)"
export CONJUR_CLOUD_FQDN="altair-poc.secretsmgr.cyberark.cloud"
export CONJUR_CLOUD_URL="https://$CONJUR_CLOUD_FQDN/api"
export CONJUR_ACCOUNT="conjur"
export NAMESPACE="conjur-cloud"
##########################################
