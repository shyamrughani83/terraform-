variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "repository_name" {
  description = "Name of the source code repository"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in the format 'owner/repo'"
  type        = string
  default     = "shyamrughani83/portfolio-v1"
}

variable "branch_name" {
  description = "Branch name to trigger the pipeline"
  type        = string
  default     = "main"
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
}
