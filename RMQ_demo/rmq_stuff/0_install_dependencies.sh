#!/bin/bash
if [[ "$(uname -a | grep Ubuntu)" == "" ]]; then
  # Note: apparently there is no socketserver for MacOS
  echo "Demo is intended to run on Ubuntu releases."
  exit -1
fi

# install python 3 if needed
if [[ "$(which python3)" == "" ]]; then
  sudo apt install python3 -y
fi

# install pip3 if needed
PIP_CHECK=$(python3 -m pip --version)
if [[ "No module named pip" == *"$PIP_CHECK"* ]]; then
  sudo add-apt-repository universe
  sudo apt update
  sudo apt-get install python3-pip -y
fi
pip3 install --upgrade setuptools
pip3 install --upgrade pip
pip3 install pika --upgrade		# needed for RabbitMQ & Forwarder
pip3 install pyparsing systemd-socketserver 	# needed for Forwarder
