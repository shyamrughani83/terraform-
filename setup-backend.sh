#!/bin/bash

# This script sets up the S3 backend for Terraform state

echo "Creating S3 bucket and DynamoDB table for Terraform state management..."

# Create a separate directory for backend setup
mkdir -p backend-setup

# Initialize and apply the backend setup configuration
cd backend-setup
terraform init
terraform apply -auto-approve

# If the backend setup was successful, configure the main project to use the backend
if [ $? -eq 0 ]; then
  echo "Backend setup successful!"
  cd ..
  
  # Re-initialize Terraform to use the new backend
  echo "Re-initializing Terraform with the S3 backend..."
  terraform init -migrate-state
  
  echo "Setup complete! You can now use Terraform with the S3 backend."
else
  echo "Backend setup failed. Please check the error messages above."
  cd ..
fi
