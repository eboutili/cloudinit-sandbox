#!/bin/bash
#
CENTOS=ami-3ecc8f46
UBUNTU=ami-1cc69e64

# aws ec2 run-instances \
#    --region us-west-2 --instance-type t2.medium --image-id $UBUNTU --security-group-ids "default" --user-data "$(cat ./k8s.txt)"

aws ec2 run-instances \
   --region us-west-2 --instance-type t2.medium --image-id $CENTOS --security-group-ids "default" --user-data "$(cat ./k8s.txt)"
