#!/bin/bash

# Create directories if they don't exist
mkdir -p app

# Check if secrets.tfvars exists, if not create it from example
if [ ! -f secrets.tfvars ]; then
  echo "Creating secrets.tfvars from example..."
  cp secrets.tfvars.example secrets.tfvars
  echo "Please update secrets.tfvars with your secure values"
fi

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

echo "Setup complete! Next steps:"
echo "1. Update terraform.tfvars with your specific values"
echo "2. Update secrets.tfvars with your secure values"
echo "3. Run 'terraform plan -var-file=\"secrets.tfvars\"' to see the execution plan"
echo "4. Run 'terraform apply -var-file=\"secrets.tfvars\"' to create the infrastructure"
