#!/bin/bash

source ../../bamboovars.sh

docker build . -t $BAMBOO_DEMO_IMAGE:latest
