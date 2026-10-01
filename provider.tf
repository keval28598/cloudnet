terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote State Backend Configuration
  backend "s3" {
    bucket         = "cloudnet-terraform-state-keval-2026"  # <-- Replace with your exact unique S3 bucket name!
    key            = "vpc/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = "us-east-1"

  # Tells Terraform to use the 'cloudnet' profile we configured in our CLI
  profile = "cloudnet"
}