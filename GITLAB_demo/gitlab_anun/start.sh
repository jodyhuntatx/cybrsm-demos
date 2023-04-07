#!/bin/bash
pushd setup
  ./0-setup-conjur.sh
  ./1-start-runner.sh
popd
echo
echo "Create a pipeline in GitLab, then create a pipeline identity in Conjur"
echo "using the create-pipeline-identity.sh script in this directory."
echo
