#!/bin/bash
set -euo pipefail

docker run -d \
    --name sf \
    --entrypoint sh \
    cyberark/dap-seedfetcher:latest \
    -c "sleep 1"

# copy startup scripts from published seedfetcher
docker cp sf:/usr/bin/start-follower.sh ./start-follower.patched
docker cp sf:/usr/bin/get-seedfile.sh ./get-seedfile.patched
docker stop sf > /dev/null && docker rm sf > /dev/null &

# get-seedfile.sh - add infinite sleep loop to keep container running after fetching seedfile
tee >> get-seedfile.patched <<EOF

# sleep loop to keep container running after fetching seedfile
while true; do
  echo "Sleeping for an hour..."
  sleep 3600
done
EOF
mv get-seedfile.patched get-seedfile.sh

# start-follower.sh - add wait loop for seedfile and master port parameter to evoke command
ex -s -c '4i|# if not set already, set CONJUR_MASTER_PORT to 443' -c x start-follower.patched
ex -s -c '5i|CONJUR_MASTER_PORT=${CONJUR_MASTER_PORT-443}' -c x start-follower.patched
ex -s -c '6i| ' -c x start-follower.patched
ex -s -c '9i|while [ ! -f "$SEEDFILE_DIR/follower-seed.tar" ]; do' -c x start-follower.patched
ex -s -c '10i|echo "waiting on seedfile..."' -c x start-follower.patched
ex -s -c '12i|done' -c x start-follower.patched
sed '/evoke configure/ s/$/ -p $CONJUR_MASTER_PORT/' start-follower.patched > start-follower.sh

docker build -t dap-seedfetcher:patched .
rm -f start-follower.* get-seedfile.*
