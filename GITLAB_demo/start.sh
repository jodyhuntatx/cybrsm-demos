#!/bin/bash
pushd setup
  ./1-start-server.sh
  ./2-setup-demos.sh
  ./3-setup-conjur.sh
  ./4-start-runner.sh
popd
