#!/bin/bash

set -e

# TODO: better way to manage this
#CLOUD_PROVIDER="google_cloud"
#CLOUD_PROVIDER="vultr"
#CLOUD_PROVIDER="azure"
CLOUD_PROVIDER="digitalocean"

# Destroy the resources
cd terraform/$CLOUD_PROVIDER/
terraform init
terraform destroy -auto-approve
cd ../../

