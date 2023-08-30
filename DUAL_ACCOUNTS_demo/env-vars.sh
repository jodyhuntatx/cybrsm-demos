# Edit this file substituting correct values for '<<YOUR_VALUE_HERE>>'

# set to 'true' for self-hosted PAM, 'false' for Pcloud
export SELF_HOSTED_PAM="false"

if $SELF_HOSTED_PAM; then
  ENV_TAG="Self-Hosted"
  SELF_HOSTED_BASE_URL=https://comp-server/PasswordVault/API
else
  ENV_TAG="Pcloud"

  # URL of your CyberArk Identity tenant
  export IDENTITY_TENANT_URL=https://aao4987.id.cyberark.cloud

  # URL of your CyberArk Privilege Cloud tenant
  PCLOUD_TENANT_URL=https://cybr-secrets.cyberark.cloud
fi

###########################################################
# THERE SHOULD BE NO NEED TO CHANGE ANYTHING BELOW THIS LINE.
# ALL VALUES BELOW ARE DERIVED FROM THOSE ABOVE
# OR PROMPTED FOR.
###########################################################

###########################################################
# A CyberArk admin user is needed for all vault administration.
# The admin user must be a Service user & Oauth2 confidential client
# in CyberArk Identity and must be granted the Privilege Cloud Administrator
# role.

# Prompt for admin user name if not already set
if [[ "$CYBERARK_ADMIN_USER" == "" ]]; then
  echo -n "Please enter the name of the CyberArk admin service user: "
  read admin_user
  export CYBERARK_ADMIN_USER=$admin_user
fi

# Prompt for admin password if not already set
if [[ "$CYBERARK_ADMIN_PWD" == "" ]]; then
  echo -n "Please enter password for $CYBERARK_ADMIN_USER: "
  unset password
  while IFS= read -r -s -n1 pass; do
    if [[ -z $pass ]]; then
       echo
       break
    else
       echo -n '*'
       password+=$pass
    fi
  done
  export CYBERARK_ADMIN_PWD=$password
fi

###########################################################
# Set CyberArk API URLS

if $SELF_HOSTED_PAM; then
  export VAULT_API_URL=$SELF_HOSTED_BASE_URL/PasswordVault/API
  export VAULT_API_URL_V1=$SELF_HOSTED_BASE_URL/PasswordVault/WebServices/PIMServices.svc
else
  # Get Identity tenant ID and tenant subdomain name
  tmp=$(echo $IDENTITY_TENANT_URL | cut -d'/' -f3)
  IDENTITY_TENANT_ID=$(echo $tmp | cut -d'.' -f1)

  tmp=$(echo $PCLOUD_TENANT_URL | cut -d'/' -f3)
  CYBERARK_SUBDOMAIN_NAME=$(echo $tmp | cut -d'.' -f1)

  export VAULT_API_URL=https://$CYBERARK_SUBDOMAIN_NAME.privilegecloud.cyberark.cloud/PasswordVault/api
  export VAULT_API_URL_V1=https://$CYBERARK_SUBDOMAIN_NAME.privilegecloud.cyberark.cloud/PasswordVault/WebServices/PIMServices.svc
fi

##########################################################
# END
