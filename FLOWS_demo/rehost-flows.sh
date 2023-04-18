#!/bin/bash -x

# Functions for converting exported Flows json files for use in other tenants
# - rehost - changes all SOURCE_* values to corresponding DEST_* values
# - generify - changes all SOURCE_* values to corresponding generic placeholders
# - specify - changes all generic placeholders to corresponding DEST_* values

# Values in exported Flows
export SOURCE_FLOWS_HOSTNAME=acj5413.flows.integration-cyberark.cloud
export SOURCE_ISPSS_HOSTNAME=aao4987.id.cyberark.cloud
export SOURCE_PCLOUD_HOSTNAME=cybr-secrets.privilegecloud.cyberark.cloud
export SOURCE_CONJUR_HOSTNAME=cybr-secrets.secretsmgr.cyberark.cloud/api

# Values for target tenant
export DEST_FLOWS_HOSTNAME=aao4987.flows.cyberark.cloud
export DEST_ISPSS_HOSTNAME=aao4987.id.cyberark.cloud
export DEST_PCLOUD_HOSTNAME=cybr-secrets.privilegecloud.cyberark.cloud
export DEST_CONJUR_HOSTNAME=cybr-secrets.secretsmgr.cyberark.cloud/api

main() {
  rehost
#  generify
#  specify
}

##############################
# changes all SOURCE_* values to corresponding DEST_* values
rehost() {
  mkdir -p ./imports
  rm ./imports/*
  pushd exports
  for i in $(ls); do
    cat $i							\
    | sed -e "s#$SOURCE_FLOWS_HOSTNAME#$DEST_FLOWS_HOSTNAME#g"	\
    | sed -e "s#$SOURCE_ISPSS_HOSTNAME#$DEST_ISPSS_HOSTNAME#g"	\
    | sed -e "s#$SOURCE_PCLOUD_HOSTNAME#$DEST_PCLOUD_HOSTNAME#g"	\
    | sed -e "s#$SOURCE_CONJUR_HOSTNAME#$DEST_CONJUR_HOSTNAME#g"	\
    > ../imports/$i
  done
}

##############################
# changes all SOURCE_* values to corresponding placeholders
generify() {
  # mkdir if it does not exist, delete all if it does
  mkdir -p ./generified
  rm ./generified/*
  pushd exports
  for i in $(ls); do
    cat $i							\
    | sed -e "s#$SOURCE_FLOWS_HOSTNAME#{{ FLOWS_HOSTNAME }}#g"	\
    | sed -e "s#$SOURCE_ISPSS_HOSTNAME#{{ ISPSS_HOSTNAME }}#g"	\
    | sed -e "s#$SOURCE_PCLOUD_HOSTNAME#{{ PCLOUD_HOSTNAME }}#g"	\
    | sed -e "s#$SOURCE_CONJUR_HOSTNAME#{{ CONJUR_HOSTNAME }}#g"	\
    > ../generified/$i
  done
}

##############################
# changes all placeholders to corresponding DEST_* values
specify() {
  rm ./imports/*
  pushd generified
  for i in $(ls); do
    cat $i							\
    | sed -e "s#{{ FLOWS_HOSTNAME }}#$DEST_FLOWS_HOSTNAME#g"	\
    | sed -e "s#{{ ISPSS_HOSTNAME }}#$DEST_ISPSS_HOSTNAME#g"	\
    | sed -e "s#{{ PCLOUD_HOSTNAME }}#$DEST_PCLOUD_HOSTNAME#g"	\
    | sed -e "s#{{ CONJUR_HOSTNAME }}#$DEST_CONJUR_HOSTNAME#g"	\
    > ../imports/$i
  done
}

main "$@"
