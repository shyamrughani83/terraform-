#!/bin/bash

echo "WARNING: This will destroy all resources created by Terraform."
echo "This action cannot be undone."
read -p "Are you sure you want to proceed? (y/n): " confirm

if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
  echo "Destroying infrastructure..."
  terraform destroy -var-file="secrets.tfvars" -auto-approve
  echo "Infrastructure destroyed."
else
  echo "Operation cancelled."
fi
