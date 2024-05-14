#!/bin/bash
source ./eks.config

EKS_CLUSTER_INFO=$(eksctl get cluster	\
	--name $EKS_CLUSTER_NAME	\
	--region $EKS_CLUSTER_REGION	\
	-o json | jq .)

if [[ "$EKS_CLUSTER_INFO" != "" ]]; then
  echo "Cluster $EKS_CLUSTER_NAME already exists."
  exit -1
fi

eksctl create cluster 				\
	--name $EKS_CLUSTER_NAME		\
	--region $EKS_CLUSTER_REGION		\
	--version $EKS_K8S_VERSION		\
	--without-nodegroup			\
	--ssh-access				\
	--ssh-public-key $EKS_SSH_PUB_KEY	\
	--external-dns-access
