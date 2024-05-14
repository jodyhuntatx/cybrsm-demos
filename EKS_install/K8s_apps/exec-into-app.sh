#!/bin/bash
source ../../config/dap.config
source ../../config/utils.sh

if [[ $# != 1 ]]; then
  echo "specify 'init', 'side' or 'inject'"
  exit -1
fi
set_namespace $TEST_APP_NAMESPACE_NAME
app_pod=$($CLI get pods | grep $1 | grep Running | awk '{print $1}')
$CLI exec -it $app_pod -- bash
