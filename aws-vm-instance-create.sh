#!/bin/bash
#
CENTOS=ami-3ecc8f46
UBUNTU=ami-1cc69e64

aws ec2 run-instances \
   --region us-west-2 --instance-type t2.medium --image-id $UBUNTU --security-group-ids "default" --user-data "$(cat ./k8s.txt)"

aws ec2 run-instances \
   --region us-west-2 --instance-type t2.medium --image-id $CENTOS --security-group-ids "default" --user-data "$(cat ./k8s.txt)"

#
# Don't forget to ensure the security group provided (called "default" in the example above) allows ssh 
# access or replace it with one that does so you can log into the instance.
#
