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
