terraform {
  backend "s3" {
    bucket         = "devsecops-project-terraform-state"
    key            = "devsecops/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
