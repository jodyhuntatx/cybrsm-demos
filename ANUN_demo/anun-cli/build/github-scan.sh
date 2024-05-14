#!/bin/bash
source ./anun-env.sh
echo "Sending scan results to $ANUN_TENANT anun tenant."
anun-cli --platform github --api-key $ANUN_APIKEY --tool-token $GITHUB_PTOKEN
