#!/bin/bash
kubectl scale --replicas=0 deployment/test-app-summon-init
kubectl scale --replicas=1 deployment/test-app-summon-init
