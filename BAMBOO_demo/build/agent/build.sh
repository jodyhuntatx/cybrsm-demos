#!/bin/bash

source ../../bamboovars.sh

docker build . -t $BAMBOO_AGENT_IMAGE:latest
