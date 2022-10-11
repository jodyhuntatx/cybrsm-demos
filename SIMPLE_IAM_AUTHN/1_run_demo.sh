#!/bin/bash
source ./demo.config
summon -p ./iam_provider.py env | grep ^DB_
