#!/bin/bash
export DEST_FLOWS_HOSTNAME=aao4987.flows.cyberark.cloud
export DEST_ISPSS_HOSTNAME=aao4987.id.cyberark.cloud
export DEST_PCLOUD_HOSTNAME=cybr-secrets.privilegecloud.cyberark.cloud
export DEST_CONJUR_HOSTNAME=cybr-secrets.secretsmgr.cyberark.cloud/api

rm ./imports/*
pushd generics
for i in $(ls); do
  cat $i							\
  | sed -e "s#{{ FLOWS_HOSTNAME }}#$DEST_FLOWS_HOSTNAME#g"	\
  | sed -e "s#{{ ISPSS_HOSTNAME }}#$DEST_ISPSS_HOSTNAME#g"	\
  | sed -e "s#{{ PCLOUD_HOSTNAME }}#$DEST_PCLOUD_HOSTNAME#g"	\
  | sed -e "s#{{ CONJUR_HOSTNAME }}#$DEST_CONJUR_HOSTNAME#g"	\
  > ../imports/$i
done
