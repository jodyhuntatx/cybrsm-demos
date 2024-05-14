#!/bin/bash
source ./anun-env.sh
echo "Sending scan results to $ANUN_TENANT anun tenant."
anun-cli --platform gitlab --api-key $ANUN_APIKEY --tool-token $GITLAB_PTOKEN
