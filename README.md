# DevSecOps Infrastructure as Code

This repository contains Terraform code to provision a complete AWS infrastructure for a DevSecOps project.

## Architecture

The infrastructure includes:

- VPC with public and private subnets across multiple availability zones
- EC2 instances for application hosting
- ECS cluster with EC2 instances for containerized applications
- ECR repository for Docker images
- RDS MySQL database for persistent storage
- Security groups for all resources
- CI/CD pipeline using AWS CodePipeline, CodeBuild, and GitHub integration
- S3 backend for Terraform state management

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0+)
- AWS CLI configured with appropriate credentials
- SSH key pair named "shyam-ecs-test" in the ap-south-1 region
- GitHub repository (https://github.com/shyamrughani83/portfolio-v1.git)

## Getting Started

### 1. Set up the S3 Backend

First, set up the S3 bucket and DynamoDB table for Terraform state management:

```bash
./setup-backend.sh
```

This script will:
- Create an S3 bucket named "devsecops-project-terraform-state"
- Enable versioning and encryption for the bucket
- Create a DynamoDB table for state locking
- Configure Terraform to use the S3 backend

### 2. Deploy the Infrastructure

After setting up the backend:

```bash
# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

## Configuration Details

The configuration is set up with the following values:

- AWS Region: ap-south-1 (Mumbai)
- EC2 Key Pair: shyam-ecs-test
- Database Password: Shyam123
- GitHub Repository: shyamrughani83/portfolio-v1
- Terraform State Bucket: devsecops-project-terraform-state

## GitHub Connection Setup

After applying the Terraform configuration:

1. Go to the AWS Console > Developer Tools > Settings > Connections
2. Find the connection created by Terraform (named like "devsecops-project-gh-conn-dev")
3. Click "Update pending connection"
4. Follow the prompts to authorize AWS to access your GitHub repository
5. Once the connection is complete, the pipeline will be able to access your GitHub repository

## Important Note About AWS Account ID

Before deploying, you should replace the placeholder "ACCOUNT_ID_PLACEHOLDER" in the CodeBuild environment variables with your actual AWS account ID. You can find this by running:

```
aws sts get-caller-identity --query Account --output text
```

## CI/CD Pipeline

The CI/CD pipeline consists of:

1. **Source Stage**: Pulls code from your GitHub repository
2. **Build Stage**: 
   - Builds a Docker image from your code
   - Pushes the image to Amazon ECR
3. **Deploy Stage**: 
   - Deploys the Docker image to your ECS cluster running on EC2 instances

## ECS Cluster

The ECS cluster is configured to:
- Use EC2 instances instead of Fargate
- Auto-scale based on demand
- Run your containerized application
- Expose the application through an Application Load Balancer

## Modules

- **VPC**: Network infrastructure
- **Security Group**: Firewall rules for all resources
- **EC2**: Compute instances
- **ECS**: Container orchestration with EC2 instances
- **RDS**: Database services
- **CodePipeline**: CI/CD pipeline with GitHub integration

## Outputs

After successful deployment, you'll get:
- VPC ID
- Subnet IDs
- EC2 instance IDs and public IPs
- ECS cluster and service names
- RDS endpoint
- CodePipeline name and GitHub connection status

## Cleanup

To destroy the infrastructure:

```
terraform destroy
```

Note: The S3 bucket for Terraform state has `prevent_destroy` set to true. To delete it, you'll need to:
1. Go to the backend-setup directory
2. Remove the `prevent_destroy` lifecycle rule from main.tf
3. Run `terraform apply` to update the bucket configuration
4. Then run `terraform destroy`
