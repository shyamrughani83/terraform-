aws_region = "ap-south-1"
project_name = "devsecops-project"
environment = "dev"

# VPC
vpc_cidr = "10.0.0.0/16"
availability_zones = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

# EC2
ec2_instance_type = "t3.micro"
key_name = "shyam-ecs-test"

# RDS
db_name = "devsecopsdb"
db_username = "admin"
db_password = "Shyam123"
db_instance_class = "db.t3.micro"

# CodePipeline
repository_name = "devsecops-repo"
branch_name = "main"
# Static Website
static_github_repository = "shyamrughani83/static-website"
static_branch_name = "main"
