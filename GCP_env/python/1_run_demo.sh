#!/bin/bash
source ../aws.config
source ../demo.config
summon -p ./iam_provider.py env | grep ^DB_
