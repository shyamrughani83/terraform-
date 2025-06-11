variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "static_github_repository" {
  description = "GitHub repository for static website in the format 'owner/repo'"
  type        = string
}

variable "static_branch_name" {
  description = "Branch name to trigger the static website pipeline"
  type        = string
  default     = "main"
}
