#!/bin/bash
sudo yum update
sudo yum install -y python3 python3-pip
pip3 install --user keyring
python3 -m pip3 install --user keyrings.alt
echo "Set Conjur admin password:"
keyring -b keyrings.alt.file.PlaintextKeyring set conjur adminpwd
echo "To retrive admin password:"
echo "  keyring -b keyrings.alt.file.PlaintextKeyring get conjur adminpwd"
echo
