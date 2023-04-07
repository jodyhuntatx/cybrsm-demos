#!/bin/bash

# Values in exported Flows
export SOURCE_FLOWS_HOSTNAME=acj5413.flows.integration-cyberark.cloud
export SOURCE_ISPSS_HOSTNAME=aao4987.id.cyberark.cloud
export SOURCE_PCLOUD_HOSTNAME=cybr-secrets.privilegecloud.cyberark.cloud
export SOURCE_CONJUR_HOSTNAME=cybr-secrets.secretsmgr.cyberark.cloud/api

# Values in target tenant
export DEST_FLOWS_HOSTNAME=aao4987.flows.cyberark.cloud
export DEST_ISPSS_HOSTNAME=aao4987.id.cyberark.cloud
export DEST_PCLOUD_HOSTNAME=cybr-secrets.privilegecloud.cyberark.cloud
export DEST_CONJUR_HOSTNAME=cybr-secrets.secretsmgr.cyberark.cloud/api

rm ./imports/*
pushd exports
for i in $(ls); do
  cat $i							\
  | sed -e "s#$SOURCE_FLOWS_HOSTNAME#$DEST_FLOWS_HOSTNAME#g"	\
  | sed -e "s#$SOURCE_ISPSS_HOSTNAME#DEST_ISPSS_HOSTNAME#g"	\
  | sed -e "s#$SOURCE_PCLOUD_HOSTNAME#DEST_PCLOUD_HOSTNAME#g"	\
  | sed -e "s#$SOURCE_CONJUR_HOSTNAME#DEST_CONJUR_HOSTNAME#g"	\
  > ../imports/$i
done
