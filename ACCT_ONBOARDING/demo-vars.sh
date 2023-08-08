# Edit this file substituting correct values for '<<YOUR_VALUE_HERE>>'

##################################################
# CyberArk tenant values

# URL of your CyberArk Identity tenant
export IDENTITY_TENANT_URL=https://aao4987.id.cyberark.cloud

# URL of your CyberArk Privilege Cloud tenant
export PCLOUD_TENANT_URL=https://cybr-secrets.cyberark.cloud

export INSTALLERUSER=installeruser@cyberark.cloud.3357
export INSTALLERUSER_PASSWORD=$(keyring get cybrid installeruserpwd)

###########################################################
# THERE SHOULD BE NO NEED TO CHANGE ANYTHING BELOW THIS LINE.
# ALL VALUES BELOW ARE DEFAULTS, PRESET, DERIVED FROM ABOVE
# OR PROMPTED FOR.
###########################################################

# Get Identity tenant ID and tenant subdomain name
tmp=$(echo $IDENTITY_TENANT_URL | cut -d'/' -f3)
export IDENTITY_TENANT_ID=$(echo $tmp | cut -d'.' -f1)

tmp=$(echo $PCLOUD_TENANT_URL | cut -d'/' -f3)
export CYBERARK_SUBDOMAIN_NAME=$(echo $tmp | cut -d'.' -f1)

###########################################################
# A CyberArk admin user is needed for all vault administration.
# The admin user must be a Service user & Oauth2 confidential client
# in CyberArk Identity and must be granted the Privilege Cloud Administrator
# role.

# Prompt for admin user name if not already set
if [[ "$CYBERARK_ADMIN_USER" == "" ]]; then
  echo -n "Please enter the name of the Pcloud admin service user: "
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

export PCLOUD_URL=https://$CYBERARK_SUBDOMAIN_NAME.privilegecloud.cyberark.cloud/PasswordVault/api
export PCLOUD_URL_V1=https://$CYBERARK_SUBDOMAIN_NAME.privilegecloud.cyberark.cloud/PasswordVault/WebServices/PIMServices.svc
##########################################################
# END
