#!/bin/bash
##########################################
##  This script executes on local host  ##
##  All others execute on AZURE host    ##
##########################################

SETUP_DIR=./conjur_setup
source $SETUP_DIR/azure.config

# Location of local Conjur appliance tarfile to copy to AZURE
CONJUR_TARFILE_SOURCE_DIR=~/conjur-install-images

main() {
  if [[ "$AZURE_PUB_DNS" == "" ]]; then
    echo "Please edit $SETUP_DIR/azure.config and set AZURE_PUB_DNS to DNS name of Conjur host."
    exit -1
  fi
  scp_appliance_image_to_cloud
  scp_subdirs_to_cloud

  # exec to AZURE EC2 instance to install & run demo
  ssh -i $AZURE_SSH_KEY $LOGIN_USER@$AZURE_PUB_DNS 
}

##########################################
scp_appliance_image_to_cloud() {
  # Copy over appliance tarfile...
  set -x
  echo "mkdir $IMAGE_DIR" | ssh -i $AZURE_SSH_KEY $LOGIN_USER@$AZURE_PUB_DNS
  scp -i $AZURE_SSH_KEY \
	$CONJUR_TARFILE_SOURCE_DIR/$CONJUR_APPLIANCE_IMAGE_FILE \
	$LOGIN_USER@$AZURE_PUB_DNS:$IMAGE_DIR/
}

##########################################
scp_subdirs_to_cloud() {
  # Copy subdirectories to AZURE
  scp -r -i $AZURE_SSH_KEY $SETUP_DIR $LOGIN_USER@$AZURE_PUB_DNS:~ 
  for i in $DEMO_DIRS; do
    scp -r -i $AZURE_SSH_KEY $i $LOGIN_USER@$AZURE_PUB_DNS:~ 
  done
}

main "$@"
