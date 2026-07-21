terraform {
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.37"
    }
  }

  backend "s3" {
    bucket       = "edp-tfstate-464868388894-us-east-1-an"
    key          = "edp/bootstrap/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "emr-data-platform"
      ManagedBy = "terraform"
      Stack     = "bootstrap"
    }
  }
}
