variable "aws_region" {
  description = "AWS region for all resources in this environment."
  type        = string
  default     = "us-east-1"
}

variable "env" {
  description = "Environment name used in resource naming and tagging."
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project short name, used as the resource name prefix."
  type        = string
  default     = "edp"
}

variable "lakeformation_admin_arn" {
  description = "IAM role ARN registered as Lake Formation Data Lake Administrator."
  type        = string
}