#!/bin/bash
##########################################
##  This script executes on local host  ##
##  All others execute on GCP host    ##
##########################################

SETUP_DIR=./conjur_setup
source $SETUP_DIR/gcp.config

# Location of local Conjur appliance tarfile to copy to GCP
CONJUR_TARFILE_SOURCE_DIR=~/conjur-install-images

main() {
  if [[ "$GCP_PUB_DNS" == "" ]]; then
    echo "Please edit $SETUP_DIR/gcp.config and set GCP_PUB_DNS to DNS name of Conjur host."
    exit -1
  fi
  scp_appliance_image_to_cloud
  scp_subdirs_to_cloud

  # exec to GCP EC2 instance to install & run demo
  ssh -i $GCP_SSH_KEY $LOGIN_USER@$GCP_PUB_DNS
}

##########################################
scp_appliance_image_to_cloud() {
  # Copy over appliance tarfile...
  set -x
  echo "mkdir $IMAGE_DIR" | ssh -i $GCP_SSH_KEY $LOGIN_USER@$GCP_PUB_IP
  scp -i $GCP_SSH_KEY \
	$CONJUR_TARFILE_SOURCE_DIR/$CONJUR_APPLIANCE_IMAGE_FILE \
	$LOGIN_USER@$GCP_PUB_IP:$IMAGE_DIR/
}

##########################################
scp_subdirs_to_cloud() {
  # Copy subdirectories to GCP
  scp -r -i $GCP_SSH_KEY $SETUP_DIR $LOGIN_USER@$GCP_PUB_IP:~ 
  for i in $DEMO_DIRS; do
    scp -r -i $GCP_SSH_KEY $i $LOGIN_USER@$GCP_PUB_IP:~ 
  done
}

main "$@"
