#!/bin/bash

set -e

# TODO: better way to manage this
#CLOUD_PROVIDER="google_cloud"
CLOUD_PROVIDER="vultr"

# check for ssh key
if [ ! -e "$HOME/.ssh/id_ed25519.pub" ]
then
  echo "SSH key does not exist"
  exit 1
fi

# check for env var
if [ "$CLOUD_PROVIDER" == "google_cloud" ]
then
  if [ -z "${GOOGLE_APPLICATION_CREDENTIALS}" ]
  then
    echo "GOOGLE_APPLICATION_CREDENTIALS is not set"
    exit 1
  fi
elif [ "$CLOUD_PROVIDER" == "vultr" ]
then
  if [ -z "${VULTR_API_KEY}" ]
  then
    echo "VULTR_API_KEY is not set"
    exit 1
  fi
fi

# Apply the Terraform (create an instance) + Extract Terraform output (get created instance address)
cd terraform/$CLOUD_PROVIDER/
terraform init
terraform apply -auto-approve
instance_ipv4=$(terraform output -raw instance_ipv4)
instance_username=$(terraform output -raw instance_username)
cd ../../

# Wait for the host to come alive on port 22
echo "Waiting for ${instance_ipv4} to become available on port 22..."
while ! nc -z ${instance_ipv4} 22
do
  sleep 1
done
echo "${instance_ipv4} is now available."

# Remove any old fingerprint from IPs being re-used
ssh-keygen -R $instance_ipv4

# Accept the SSH fingerprint
if ! ssh-keygen -F $instance_ipv4 > /dev/null
then
  ssh-keyscan -H $instance_ipv4 >> ~/.ssh/known_hosts
fi

# Create Ansible inventory file
echo "[my_instance]" > /tmp/hosts.ini
echo "${instance_ipv4} ansible_user=${instance_username}" >> /tmp/hosts.ini

# Configurable variables
export ARGOCD_ADMIN_PASSWORD='$2a$12$ZlAjJr.wa9nedDyAC5RFq.gEn6uSy73Kupp1KQ5DG3y/EVY9YOdiS'
export ARGOCD_ADMIN_PASSWORD_MTIME=$(date +%FT%T%Z)

# Run the Ansible playbooks
ansible-playbook -i /tmp/hosts.ini ./ansible/setup-playbook.yml
ansible-playbook -i /tmp/hosts.ini ./ansible/k3s-playbook.yml
ansible-playbook -i /tmp/hosts.ini ./ansible/argocd-playbook.yml
ansible-playbook -i /tmp/hosts.ini ./ansible/hyperswitch-playbook.yml
