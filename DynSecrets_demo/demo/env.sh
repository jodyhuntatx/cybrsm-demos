# Identity variables - SE tenant
export IDENTITY_TENANT_ID=aao4987
export CYBERARK_IDENTITY_URL=https://$IDENTITY_TENANT_ID.id.cyberark.cloud

# Conjur Cloud variables
export CYBERARK_CCLOUD_API=https://cybr-secrets.secretsmgr.cyberark.cloud/api

# Privilege Cloud variables
export CYBERARK_VAULT_URL=https://cybr-secrets.privilegecloud.cyberark.cloud/api
export CYBERARK_EMAIL_DOMAIN=cyberark.cloud.3357
export CYBERARK_ADMIN_USER=jody_bot@$CYBERARK_EMAIL_DOMAIN
export CYBERARK_ADMIN_PWD=$(keyring get cybrid jodybotpwd)
