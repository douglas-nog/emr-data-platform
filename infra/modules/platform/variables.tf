variable "project" {
  description = "Project short name, used as the resource name prefix."
  type        = string
}

variable "env" {
  description = "Environment name (dev, hom, prod)."
  type        = string
}

variable "emr_release_label" {
  description = "EMR release. 7.13.0 or later is required for dbt over Spark Connect."
  type        = string
  default     = "emr-7.13.0"
}

variable "emr_max_cpu" {
  description = "Aggregate vCPU ceiling across concurrent jobs. Cost guardrail, not a scaling target."
  type        = string
  default     = "32 vCPU"
}

variable "emr_max_memory" {
  description = "Aggregate memory ceiling across concurrent jobs."
  type        = string
  default     = "128 GB"
}

variable "emr_idle_timeout_minutes" {
  description = "Idle time before the application stops. Guards against forgotten sessions."
  type        = number
  default     = 15
}

variable "log_retention_days" {
  description = "Days to keep EMR job and Spark event logs."
  type        = number
  default     = 30
}