#!/bin/bash
########################################
##  This script executes on AWS host  ##
########################################

source ./gcp.config

if [[ "$(cat /etc/os-release | grep 'Debian')" == "" ]]; then
  echo "These installation scripts assume."
  exit -1
fi

main() {
  install_keyring
  install_docker
  load_images
  ./start_conjur
}

install_keyring() {
  sudo apt update
  sudo apt install -y python3 python3-pip
  python3 -m pip install keyrings.alt
  echo "Set Conjur admin password:"
  keyring set conjur adminpwd
}

install_docker() {
  # Install, enable, start, verify and cleanup docker package
  sudo apt-get remove -qy docker docker-engine docker.io containerd runc
  sudo apt-get update -qy
  sudo apt-get install -qy \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    dnsutils
  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
  sudo apt-key fingerprint 0EBFCD88
  sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"
  sudo apt-get update
  sudo apt-get install -qy docker-ce docker-ce-cli containerd.io
}

load_images() {
  echo "Loading Conjur appliance image..."
  sudo docker load -i $IMAGE_DIR/$CONJUR_APPLIANCE_IMAGE_FILE
}

main "$@"
