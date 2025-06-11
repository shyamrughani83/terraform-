provider "aws" {
  region = var.aws_region
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  project_name         = var.project_name
  environment          = var.environment
}

# Security Group Module
module "security_group" {
  source = "./modules/security_group"
  
  vpc_id       = module.vpc.vpc_id
  project_name = var.project_name
  environment  = var.environment
}

# EC2 Module
module "ec2" {
  source = "./modules/ec2"
  
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_id = module.security_group.ec2_sg_id
  instance_type     = var.ec2_instance_type
  key_name          = var.key_name
  project_name      = var.project_name
  environment       = var.environment
}

# ECS Module
module "ecs" {
  source = "./modules/ecs"
  
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_id = module.security_group.ecs_sg_id
  project_name      = var.project_name
  environment       = var.environment
  key_name          = var.key_name
}

# RDS Module
module "rds" {
  source = "./modules/rds"
  
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_subnet_ids
  security_group_id     = module.security_group.rds_sg_id
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
  db_instance_class     = var.db_instance_class
  project_name          = var.project_name
  environment           = var.environment
}

# CodePipeline Module
module "codepipeline" {
  source = "./modules/codepipeline"
  
  project_name      = var.project_name
  environment       = var.environment
  repository_name   = var.repository_name
  github_repository = var.github_repository
  branch_name       = var.branch_name
  ecs_cluster_name  = module.ecs.cluster_name
  ecs_service_name  = module.ecs.service_name
}

# CloudFront Module
module "cloudfront" {
  source = "./modules/cloudfront"
  
  project_name           = var.project_name
  environment            = var.environment
  static_github_repository = var.static_github_repository
  static_branch_name     = var.static_branch_name
}
