#!/bin/bash
export AWS_PUB_DNS=ec2-13-58-161-67.us-east-2.compute.amazonaws.com
ssh -i $AWS_SSH_KEY ubuntu@$AWS_PUB_DNS
