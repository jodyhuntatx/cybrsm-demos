export CURL="curl -sk"

# Identity variables - SE tenant
export IDENTITY_TENANT_ID=aao4987
export IDENTITY_URL=https://$IDENTITY_TENANT_ID.id.cyberark.cloud
export IDENTITY_DOMAIN=cyberark.cloud.3357

# IDP app endpoint and Admin user
export IDENTITY_APP_ID=__idaptive_cybr_user_oidc
export IDENTITY_ADMIN_USER=jody_bot@$IDENTITY_DOMAIN
export IDENTITY_ADMIN_PWD=$(keyring get cybrid jodybotpwd)
export IDENTITY_WORKLOAD_ID=jody_bot@$IDENTITY_DOMAIN

# Conjur Cloud variables
CONJUR_URL=https://cybr-secrets.secretsmgr.cyberark.cloud/api
CONJUR_DOMAIN=cyberark.cloud.3357
# Service user
CONJUR_ADMIN_USER=jody_bot@$CONJUR_DOMAIN
CONJUR_ADMIN_PWD=$(keyring get cybrid jodybotpwd)
# non Service user
#CONJUR_ADMIN_USER=jody_hunt@$CONJUR_DOMAIN
#CONJUR_ADMIN_PWD=$(keyring get cybrid admpwd)

# Privilege Cloud variables
PCLOUD_URL=https://cybr-secrets.privilegecloud.cyberark.cloud/api
PCLOUD_DOMAIN=cyberark.cloud.3357
PCLOUD_ADMIN_USER=jody_hunt@$PCLOUD_DOMAIN
PCLOUD_ADMIN_PWD=$(keyring get cybrid admpwd)
