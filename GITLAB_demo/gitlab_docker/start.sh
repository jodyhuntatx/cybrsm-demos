#!/bin/bash
pushd setup
  ./1-start-server.sh
  ./2-setup-demos.sh
  ./3-setup-conjur.sh
  ./4-start-runner.sh
popd
echo
echo "Create a pipeline in GitLab, then create a pipeline identity in Conjur"
echo "using the create-pipeline-identity.sh script in this directory."
echo
