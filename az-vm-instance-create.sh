#!/bin/bash
#
az vm create --name UbuntuK8sNode \
  --resource-group myResourceGroup --size Standard_B2ms --image UbuntuLTS --custom-data ./k8s.txt

az vm create --name CentOSK8sNode \
  --resource-group myResourceGroup --size Standard_B2ms --image OpenLogic:CentOS:7-CI:latest --custom-data ./k8s.txt

#
# Don't forget to replace the resource-group parameter above with your own
#
