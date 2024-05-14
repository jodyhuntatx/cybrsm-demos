#!/bin/bash
set -euo pipefail
source ./conjur-cloud-vars.sh
echo "Deleting workload with Helm..."
helm delete conjur-cloud-k8s-eks-secrets 
