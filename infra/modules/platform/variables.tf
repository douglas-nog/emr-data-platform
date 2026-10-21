variable "project" {
  description = "Project short name, used as the resource name prefix."
  type        = string
}

variable "env" {
  description = "Environment name (dev, hom, prod)."
  type        = string
}

variable "log_retention_days" {
  description = "Days to keep Glue job and Spark event logs."
  type        = number
  default     = 30
}

variable "lakeformation_admin_arn" {
  description = "IAM role ARN registered as Lake Formation Data Lake Administrator."
  type        = string
}

variable "domains" {
  description = "Domain values for the LF-Tag taxonomy."
  type        = list(string)
  default     = ["macro", "fundos"]
}

variable "environments" {
  description = "Environment values for the LF-Tag taxonomy."
  type        = list(string)
  default     = ["dev", "hom", "prod"]
}
