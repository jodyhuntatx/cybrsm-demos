#!/bin/bash -x

 

clear

 

PS3="Select EC2 instance: "

 

select opt in tools.conjur.dev dapmaster.conjur.dev quit; do
  case $opt in
    tools.conjur.dev)
      echo "ssh jhunt@ec2-user#aws.amazon.com@ip-10-0-30-86.us-west-1.compute.internal@psmp.conjur.dev"
      ssh jhunt@ec2-user#aws.amazon.com@ip-10-0-30-86.us-west-1.compute.internal@psmp.conjur.dev
      clear
      ;;
    dapmaster.conjur.dev)
      echo "ssh jhunt@ec2-user#aws.amazon.com@ip-10-0-20-237.us-west-1.compute.internal@psmp.conjur.dev"
      ssh jhunt@ec2-user#aws.amazon.com@ip-10-0-20-237.us-west-1.compute.internal@psmp.conjur.dev
      clear
      ;;
    quit)
      break;;
    *)
      echo "Invalid option $REPLY";;
  esac
done

 

# (tools) ssh jhunt@ec2-user#aws.amazon.com@ip-10-0-30-86.us-west-1.compute.internal@54.193.213.186
# (tools) ssh jhunt@ec2-user#aws.amazon.com@ip-10-0-30-86.us-west-1.compute.internal@psmp.conjur.dev
# (dapmaster) ssh jhunt@ec2-user#aws.amazon.com@ip-10-0-20-237.us-west-1.compute.internal@52.53.232.160
