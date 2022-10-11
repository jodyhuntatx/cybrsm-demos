#!/bin/bash
source conjur_setup/azure.config

ssh -i $AZURE_SSH_KEY $LOGIN_USER@$AZURE_PUB_DNS
