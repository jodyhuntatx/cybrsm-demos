#!/bin/bash

# Helpful commands
# subscription-manager list --all --available | grep "Subscription Name"
# subscription-manager list --consumed | grep "Subscription Name"
# subscription-manager repos --list
# subscription-manager repos --list-enabled

export AAP_VERSION=2.1
export AAP_PATCH_VERSION=0-1
export SUBS_POOL_ID=8a85f9997ed94216017edf27efcf28a8
export REPO_ID=ansible-automation-platform-$AAP_VERSION-for-rhel-8-x86_64-rpms

set -x
subscription-manager attach --pool $SUBS_POOL_ID
subscription-manager repos --enable $REPO_ID
tar xvf ansible-automation-platform-setup-bundle-$AAP_VERSION.$AAP_PATCH_VERSION.tar.gz
cd ansible-automation-platform-setup-bundle-$AAP_VERSION.$AAP_PATCH_VERSION
mv inventory inventory.template
cp ../ansible-inventory-singlenode ./inventory
./setup.sh
