#!/bin/bash
##############################################################################################
#  Copyright Accenture. All Rights Reserved.
#
#  SPDX-License-Identifier: Apache-2.0
##############################################################################################

set -e

echo "Starting local development build process..."

echo "Adding env variables..."
export PATH=/root/bin:$PATH

# Path to k8s config file
export KUBECONFIG=/home/bevel/build/config

echo "Validating network yaml"
ajv validate -s /home/bevel/platforms/network-schema.json -d /home/bevel/build/network-local.yaml 

echo "Running the playbook with kubectl validation skipped..."
# Skip setup-environment.yaml which contains the kubectl validation
exec ansible-playbook -vv /home/bevel/platforms/hyperledger-fabric/configuration/deploy-network.yaml --inventory-file=/home/bevel/platforms/shared/inventory/ -e "@/home/bevel/build/network-local.yaml" -e 'ansible_python_interpreter=/usr/bin/python3' -e 'add_new_org=false'

