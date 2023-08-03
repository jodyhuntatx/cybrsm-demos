##########################################
## Conjur_Cloud_Vars
##
# Platform tenant id
export IDENTITY_TENANT_ID="aao4987"
#export IDENTITY_TENANT_ID="aaw4398"

# Conjur Cloud values
export CONJUR_CLOUD_FQDN="cybr-secrets.secretsmgr.cyberark.cloud"
#export CONJUR_CLOUD_FQDN="altair-poc.secretsmgr.cyberark.cloud"
export CONJUR_CLOUD_URL="https://$CONJUR_CLOUD_FQDN/api"
export CONJUR_ACCOUNT="conjur"

# Admin service account user
export CONJUR_ADMIN_USER=jody_bot@cyberark.cloud.3357
#export CONJUR_ADMIN_USER="conjur_bot@altairpd.com"
export CONJUR_ADMIN_PWD="$(keyring get cybrid jodybotpwd)"

# Automation user
export CONJUR_AUTHN_LOGIN=host/data/workloads/autobot
export CONJUR_AUTHN_API_KEY=3fht5z8kasr6w1399m8a1znt7273j1tr301bw875k2n124ers878mr

# K8s stuff
export NAMESPACE="eso-app"
##########################################
