#!/bin/bash -x
source splunk-demo.config

curl -sk -o /dev/null -u $SPLUNK_ACCOUNT:$SPLUNK_ACCOUNT_PASSWORD \
https://$CONJUR_MASTER_HOST_NAME:$SPLUNK_REST_PORT/servicesNS/$SPLUNK_ACCOUNT/search/data/transforms/extractions \
-d REGEX='^[^ \n]* (?P<IP_address>[^ ]+)(?:[^ \n]* ){4}(?P<HTTP_code>\d+)(?:[^ \n]* ){3}(?P<Client>"\w+/\d+\.\d+\s+\(\w+;\s+\w+\s+\w+\s+\w+\s+\w+\s+\d+_\d+_\d+\)\s+\w+/\d+\.\d+\s+\(\w+,\s+\w+\s+\w+\)\s+\w+/\d+\.\d+\.\d+\.\d+\s+\w+/\d+\.\d+")' -d SOURCE_KEY=_raw -d name=nginx_access_transform

