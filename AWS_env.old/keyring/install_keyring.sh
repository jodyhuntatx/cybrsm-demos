#!/bin/bash
sudo apt-get install python3
python -m pip install keyrings.alt
echo "Set Conjur admin password:"
keyring set conjur adminpwd
