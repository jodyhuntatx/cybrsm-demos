#!/bin/bash +e
source ../../config/dap.config
source ../../config/utils.sh

# As Developer:
#  - builds images (if CONNECTED)
#  - tags local test-app and seed-fether images and pushes to registry.
#
# Registry image tags are:
#  $TEST_APP_REG_IMAGE
#  $AUTHENTICATOR_CLIENT_REG_IMAGE
#  $SECRETS_PROVIDER_REG_IMAGE
#
# Registry image names are defined in the $PLATFORM.config file and referenced in deployment manifests.

./precheck_k8s_apps.sh

login_as $DEVELOPER_USERNAME $DEVELOPER_PASSWORD

if $CONNECTED; then
  pushd build
    ./build.sh
  popd
fi

set -x
registry_login

# tag & push local K8S_followers images to registry
docker tag $TEST_APP_IMAGE $TEST_APP_REG_IMAGE
docker tag $AUTHENTICATOR_CLIENT_IMAGE $AUTHENTICATOR_CLIENT_REG_IMAGE
docker tag $SECRETS_PROVIDER_IMAGE $SECRETS_PROVIDER_REG_IMAGE

if ! $MINIKUBE; then
  docker push $TEST_APP_REG_IMAGE
  docker push $AUTHENTICATOR_CLIENT_REG_IMAGE
  docker push $SECRETS_PROVIDER_REG_IMAGE
fi
