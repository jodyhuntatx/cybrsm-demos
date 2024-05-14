#!/bin/bash

# Copied from: https://https://github.com/conjurdemos/conjur-iam-api-key
# on March 18, 2020

sudo apt-get -y install pip pip3
pip3 install --user conjur-client
git clone https://github.com/conjurdemos/conjur-iam-api-key.git
cd conjur-iam-api-key; pip3 install --user .
