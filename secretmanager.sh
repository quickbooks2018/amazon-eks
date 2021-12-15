#!/bin/bash

######################################
# Aws-Secret-Manager Secret CSI Driver
######################################
cd secret-manager
kubectl apply -f secrets-store-csi-driver
kubectl apply -f aws-provider-installer

# End
