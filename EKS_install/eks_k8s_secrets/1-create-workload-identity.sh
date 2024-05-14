#!/bin/bash
set -euo pipefail
source ./conjur-cloud-vars.sh
echo "Creating workload identity & granting it access to secrets..."

echo "################"
echo "Loading policy file: workload-identity.yml..."
cat policy/workload-identity.yml
echo "################"
./ccloud-cli.sh append data/workloads policy/workload-identity.yml
echo "################"
echo "Loading policy file: workload-access.yml..."
cat policy/workload-access.yml
echo "################"
./ccloud-cli.sh append data		policy/workload-access.yml

