#!/bin/bash
set -eou pipefail
source ./env/mtls-demo.config
source ../../config/conjur.config
source ../env/pkiaas.env
source ../env/sandbox.env

docker-compose up -d 
