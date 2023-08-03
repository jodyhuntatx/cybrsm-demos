export CONJUR_HOME=${CONJUR_HOME:-~/Conjur/cybrsm-demos}

###########################
export CURL="curl -sk"
export BIN_DIR=$CONJUR_HOME/CCLOUD_DEMO

# Conjur Cloud CLI env vars
export IDENTITY_TENANT_ID=aao4987
export CONJUR_CLOUD_URL=https://cybr-secrets.secretsmgr.cyberark.cloud/api
export CONJUR_ADMIN_USER=jody_bot@cyberark.cloud.3357
export CONJUR_ADMIN_PWD=$(keyring get cybrid jodybotpwd)

# GitLab demo container variables
export DOCKER=docker
export GITLAB_HOST_NAME=gitlab.com

# runner vars
export GITLAB_RUNNER_IMAGE=gitlab/gitlab-runner:latest
export GITLAB_RUNNER_CONTAINER=gitlab-docker
export GITLAB_RUNNER_VOLUME=gitlab-docker

###########################
# authn-jwt config values
export SERVICE_ID=gitlab
export JWT_POLICY_TEMPLATE=authn-jwt.yml.template
export TOKEN_APP_PROPERTY=project_path
export IDENTITY_PATH=data
export JWT_ISSUER=$GITLAB_HOST_NAME

# project_path value is the gitlab-account/project-name - it is the JWT claim for authn-jwt
export WORKLOAD_ID=jodyhuntatx1/conjur-demo2

# according to: https://gitlab.com/gitlab-org/gitlab/-/issues/333595
# the URI "https://<host>/~/jwks" returns correct keys in AWS, but for
# self-hosted gitlab it not accessible without authentication.
# "https://<host>/oauth/discovery/keys" seems to work for both.
export JWKS_URI=https://$GITLAB_HOST_NAME/oauth/discovery/keys

###########################
export VAULT_NAME=vault
export SAFE_NAME=JodyDemo
export ACCOUNT_NAME=MySQL-DB
export RETRIEVE_VAR_NAME=$VAULT_NAME/$SAFE_NAME/$ACCOUNT_NAME/password
