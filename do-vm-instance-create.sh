#!/bin/bash
#
doctl compute droplet create UbuntuK8sNode \
  --region sfo2 --size 8gb --image ubuntu-16-04-x64 --user-data-file ./k8s.txt

doctl compute droplet create CentOSK8sNode \
  --region sfo2 --size 8gb --image centos-7-x64 --user-data-file ./k8s.txt
