#!/bin/bash
pushd 2-deployment
./2-mysqldb-deploy.sh clean
./1-follower-deploy.sh clean
popd
pushd 1-namespace-setup
./start clean
popd
