#!/bin/bash -x


# Functions for converting exported Flows json files for use with other tenants
# The Flows tenant can be different from the tenant hosting Privcloud and Conjur

# Local directories for Flows json files
export EXPORTED_FLOWS_DIR=exported-flows
export FLOW_TEMPLATES_DIR=flow-templates
export FLOWS_FOR_IMPORTING_DIR=flows-for-import

# Script functions
#  generify - changes all SOURCE_* values in files in EXPORTED_FLOWS_DIR
#             to generic placeholder values 
#             and writes files to FLOW_TEMPLATES_DIR.
#  specify - changes all generic placeholders in files in FLOW_TEMPLATES_DIR
#            to corresponding DEST_* values
#            and writes files to FLOWS_FOR_IMPORTING_DIR.
#  rehost - changes all SOURCE_* values in files in EXPORTED_FLOWS_DIR
#           to corresponding DEST_* values
#           and writes files to FLOWS_FOR_IMPORTING_DIR.

# Hostname values in exported Flows for converting
export SOURCE_FLOWS_HOSTNAME=acj5413.flows.integration-cyberark.cloud
export SOURCE_ISPSS_HOSTNAME=aao4987.id.cyberark.cloud
export SOURCE_PCLOUD_HOSTNAME=cybr-secrets.privilegecloud.cyberark.cloud
export SOURCE_CONJUR_HOSTNAME=cybr-secrets.secretsmgr.cyberark.cloud/api

# Hostname values in target tenant
export DEST_FLOWS_HOSTNAME=aax4917.flows.cyberark.cloud
export DEST_ISPSS_HOSTNAME=aax4917.id.cyberark.cloud
export DEST_PCLOUD_HOSTNAME=c3.privilegecloud.cyberark.cloud
export DEST_CONJUR_HOSTNAME=c3.secretsmgr.cyberark.cloud/api

main() {
  specify
exit
  generify
  rehost
}

##############################
# changes all SOURCE_* values to corresponding DEST_* values
rehost() {
  mkdir -p ./$FLOWS_FOR_IMPORTING_DIR
  rm ./$FLOWS_FOR_IMPORTING_DIR/*
  pushd $EXPORTED_FLOWS_DIR
  for i in $(ls); do
    cat $i							\
    | sed -e "s#$SOURCE_FLOWS_HOSTNAME#$DEST_FLOWS_HOSTNAME#g"	\
    | sed -e "s#$SOURCE_ISPSS_HOSTNAME#$DEST_ISPSS_HOSTNAME#g"	\
    | sed -e "s#$SOURCE_PCLOUD_HOSTNAME#$DEST_PCLOUD_HOSTNAME#g"	\
    | sed -e "s#$SOURCE_CONJUR_HOSTNAME#$DEST_CONJUR_HOSTNAME#g"	\
    > ../$FLOWS_FOR_IMPORTING_DIR/$i
  done
}

##############################
# changes all SOURCE_* values to corresponding placeholders
generify() {
  # mkdir if it does not exist, delete all if it does
  mkdir -p ./$FLOW_TEMPLATES_DIR
  rm ./$FLOW_TEMPLATES_DIR/*
  pushd $EXPORTED_FLOWS_DIR
  for i in $(ls); do
    cat $i							\
    | sed -e "s#$SOURCE_FLOWS_HOSTNAME#{{ FLOWS_HOSTNAME }}#g"	\
    | sed -e "s#$SOURCE_ISPSS_HOSTNAME#{{ ISPSS_HOSTNAME }}#g"	\
    | sed -e "s#$SOURCE_PCLOUD_HOSTNAME#{{ PCLOUD_HOSTNAME }}#g"	\
    | sed -e "s#$SOURCE_CONJUR_HOSTNAME#{{ CONJUR_HOSTNAME }}#g"	\
    > ../$FLOW_TEMPLATES_DIR/$i
  done
}

##############################
# changes all placeholders to corresponding DEST_* values
specify() {
  rm ./$FLOWS_FOR_IMPORTING_DIR/*
  pushd $FLOW_TEMPLATES_DIR
  for i in $(ls); do
    cat $i							\
    | sed -e "s#{{ FLOWS_HOSTNAME }}#$DEST_FLOWS_HOSTNAME#g"	\
    | sed -e "s#{{ ISPSS_HOSTNAME }}#$DEST_ISPSS_HOSTNAME#g"	\
    | sed -e "s#{{ PCLOUD_HOSTNAME }}#$DEST_PCLOUD_HOSTNAME#g"	\
    | sed -e "s#{{ CONJUR_HOSTNAME }}#$DEST_CONJUR_HOSTNAME#g"	\
    > ../$FLOWS_FOR_IMPORTING_DIR/$i
  done
}

main "$@"
