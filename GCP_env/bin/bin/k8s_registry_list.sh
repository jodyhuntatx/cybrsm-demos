#!/bin/bash
reg_container_id=$(docker ps | grep k8s_registry_docker | cut -d ' ' -f 1) 
docker exec $reg_container_id find /registry | grep repositories | grep -v _layers | grep -v _manifests | grep -v _uploads
