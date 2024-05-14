#!/bin/bash -x
source splunk-demo.config
if [[ $# != 1 ]]; then
  echo "Usage: $0 <dashboard-name>"
  exit -1
fi
dashboard_name=$1
curl -sk -o $dashboard_name.out -u $SPLUNK_ACCOUNT:$SPLUNK_ACCOUNT_PASSWORD \
  https://$CONJUR_MASTER_HOST_NAME:$SPLUNK_REST_PORT/servicesNS/$SPLUNK_ACCOUNT/search/data/ui/views/$dashboard_name
