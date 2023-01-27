export CONJUR_HOME=${CONJUR_HOME:-~/Conjur/cybrsm-demos}

###########################
# GitLab demo container variables
export DOCKER=docker
export GITLAB_HOST_NAME=conjur-master-minikube
export GITLAB_NETWORK=gitlab-network

# server vars
export GITLAB_SERVER_VERSION=15.7.5-ee.0
export GITLAB_SERVER_IMAGE=gitlab/gitlab-ee:$GITLAB_SERVER_VERSION
export GITLAB_SERVER_CONTAINER=gitlab-server
export GITLAB_HTTPS_PORT=10443
export GITLAB_HTTP_PORT=1080
export GITLAB_SSH_PORT=1022
export GITLAB_SHM_SIZE=1024m

# volumes for persisting container state
export GITLAB_CONFIG_VOLUME=gitlab_config
export GITLAB_LOGS_VOLUME=gitlab_logs
export GITLAB_DATA_VOLUME=gitlab_data

# runner vars
export GITLAB_RUNNER_IMAGE=gitlab/gitlab-runner:latest
export GITLAB_RUNNER_CONTAINER=gitlab-runner
export GITLAB_RUNNER_VOLUME=gitlab_runner

###########################
# authn-jwt config values
export SERVICE_ID=gitlab
export JWT_POLICY_TEMPLATE=authn-jwt.yml.template
export TOKEN_APP_PROPERTY=project_path
export IDENTITY_PATH=/apps
export JWT_ISSUER=$GITLAB_HOST_NAME

# according to: https://gitlab.com/gitlab-org/gitlab/-/issues/333595
# the URI "https://<host>/~/jwks" returns correct keys in AWS, but for
# self-hosted gitlab it not accessible without authentication.
# "https://<host>/oauth/discovery/keys" seems to work for self-hosted.
export JWKS_URI=https://$GITLAB_HOST_NAME:$GITLAB_HTTPS_PORT/oauth/discovery/keys

###########################
export VAULT_NAME=DemoVault
export LOB_NAME=CICD
export SAFE_NAME=CICD_Secrets
export RETRIEVE_VAR_NAME=$VAULT_NAME/$LOB_NAME/$SAFE_NAME/AwsAccessKeys/awsaccesskeyid
