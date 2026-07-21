terraform {
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.37"
    }
  }

  backend "s3" {
    # Remaining values come from backend.hcl (see backend.hcl.example)
    key          = "edp/dev/platform/terraform.tfstate"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "emr-data-platform"
      ManagedBy = "terraform"
      Env       = var.env
    }
  }
}
