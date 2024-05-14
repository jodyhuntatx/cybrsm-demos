#!/bin/bash
kubectl create -f ConjurSecretStore.yaml
kubectl create -f ConjurExtSecret.yaml
#kubectl create -f DockerConfigSecret.yaml
