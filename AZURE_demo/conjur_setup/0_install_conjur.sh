#!/bin/bash
########################################
##  This script executes on AWS host  ##
########################################

source ./azure.config

if [[ "$(cat /etc/os-release | grep 'Ubuntu 18')" == "" ]]; then
  echo "These installation scripts assume Ubuntu 18 (bionic)."
  exit -1
fi

main() {
  install_docker
  load_images
  ./start_conjur
}

install_docker() {
  # Install, enable, start, verify and cleanup docker package
  sudo apt-get remove -qy docker docker-engine
  sudo apt-get update -qy
  sudo apt-get install -qy \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo apt-key fingerprint 0EBFCD88
  sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
  sudo apt-get update
  sudo apt-get install -qy docker-ce
}

load_images() {
  echo "Loading Conjur appliance image..."
  sudo docker load -i $IMAGE_DIR/$CONJUR_APPLIANCE_IMAGE_FILE
}

main "$@"
