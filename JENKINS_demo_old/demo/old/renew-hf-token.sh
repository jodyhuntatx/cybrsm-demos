#!/bin/bash
JOBS_HF_NAME=jenkins/jobs_factory
JOBS_HF_FILE=jobs_hf_token.txt
HF_MINUTES=720
JOBS_HF_TOKEN=$(conjur hostfactory tokens create --duration-minutes $HF_MINUTES $JOBS_HF_NAME | jq -r .[].token)
echo $JOBS_HF_TOKEN > $JOBS_HF_FILE
