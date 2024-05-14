#!/bin/bash
set -eou pipefail
source ../../config/conjur.config
source ../env/pkiaas.env
source ../env/sandbox.env
source ./env/mtls-demo.config

docker-compose up -d 
