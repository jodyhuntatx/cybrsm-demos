#!/bin/bash

source ../../dap-service.config

LOCAL_LAB_IMAGES=(
  $LOCAL_APPLIANCE_IMAGE
  $LOCAL_APP_IMAGE
  $LOCAL_AUTHENTICATOR_IMAGE
  $LOCAL_SEEDFETCHER_IMAGE
  $LOCAL_SECRETS_PROVIDER_IMAGE
  $LOCAL_SECRETLESS_BROKER_IMAGE
)

main() {
  if [[ "$PLATFORM" == "openshift" ]]; then
    oc login -u $CYBERARK_NAMESPACE_ADMIN
  fi
  retag_local_images
  check_local_lab_image_tags
  tag_and_push_lab_images
}

#############################
retag_local_images() {
set -x
  docker tag $DOCKERHUB_APPLIANCE_IMAGE $LOCAL_APPLIANCE_IMAGE
  docker tag $DOCKERHUB_SEEDFETCHER_IMAGE  $LOCAL_SEEDFETCHER_IMAGE
  docker tag $DOCKERHUB_APP_IMAGE  $LOCAL_APP_IMAGE
  docker tag $DOCKERHUB_AUTHENTICATOR_IMAGE  $LOCAL_AUTHENTICATOR_IMAGE
  docker tag $DOCKERHUB_SECRETS_PROVIDER_IMAGE  $LOCAL_SECRETS_PROVIDER_IMAGE
  docker tag $DOCKERHUB_SECRETLESS_BROKER_IMAGE $LOCAL_SECRETLESS_BROKER_IMAGE
set +x
}

#############################
check_local_lab_image_tags() {
  all_found=true
  for img_name in "${LOCAL_LAB_IMAGES[@]}"; do
    echo -n "  Checking $img_name: "
    if [[ "$(docker image ls $img_name | grep -v REPOSITORY)" == "" ]]; then
      echo " NOT FOUND"
      all_found=false
    else
      echo "loaded"
    fi
  done
  if ! $all_found; then
    echo "Check image tags."
    exit -1
  fi    
}

#############################
tag_and_push_lab_images() {
  if [[ "$PLATFORM" == "openshift" ]]; then
    docker login -u $(oc whoami) -p $(oc whoami -t) $EXTERNAL_REGISTRY_URL
  fi
  all_found=true
  for img_name in "${LOCAL_LAB_IMAGES[@]}"; do
	docker tag $img_name $EXTERNAL_REGISTRY_URL/$CYBERARK_NAMESPACE_NAME/$img_name
        docker push $EXTERNAL_REGISTRY_URL/$CYBERARK_NAMESPACE_NAME/$img_name
  done
}

main "$@"
