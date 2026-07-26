variable "aws_region" {
  description = "AWS region where bootstrap resources are created."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project short name, used as the resource name prefix."
  type        = string
  default     = "edp"
}

variable "alert_email" {
  description = "Email address that receives cost alert notifications."
  type        = string
}

variable "budget_limit_usd" {
  description = "Monthly cost budget limit in USD."
  type        = string
  default     = "50"
}
