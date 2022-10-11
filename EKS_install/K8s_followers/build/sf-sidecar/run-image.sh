#!/bin/bash -x
set -euo pipefail
IMAGE_NAME=$1
docker run -d \
    --name sf \
    --entrypoint sh \
    $IMAGE_NAME \
    -c "sleep 100"
docker exec -it sf bash
docker stop sf >& /dev/null &&  docker rm sf >& /dev/null &
