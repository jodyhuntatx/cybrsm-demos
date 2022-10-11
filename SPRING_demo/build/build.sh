#!/bin/bash
source ../spring-demo.config
#git clone https://github.com/conjurdemos/pet-store-demo.git
#cd pet-store-demo
#./bin/build
#cd ..
set -x
docker build -t $DEMO_IMAGE .
