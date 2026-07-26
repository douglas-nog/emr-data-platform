variable "project" {
  description = "Project short name, used as the resource name prefix."
  type        = string
}

variable "env" {
  description = "Environment name (dev, hom, prod)."
  type        = string
}

variable "domain" {
  description = "Domain this ingestion function belongs to."
  type        = string
}

variable "landing_bucket" {
  description = "Landing bucket the function writes raw data to. From the domain module."
  type        = string
}

variable "source_dir" {
  description = "Path to the Lambda source package (the bcb_ingestion directory's parent)."
  type        = string
}

variable "layer_zip" {
  description = "Path to the pre-built layer.zip produced by layer/build.sh."
  type        = string
}

variable "handler" {
  description = "Lambda handler entrypoint."
  type        = string
  default     = "bcb_ingestion.handler.handler"
}

variable "runtime" {
  description = "Lambda runtime. Must match the layer build."
  type        = string
  default     = "python3.11"
}

variable "architecture" {
  description = "Lambda architecture. Must match the layer build."
  type        = string
  default     = "arm64"
}

variable "timeout_seconds" {
  description = "Function timeout. One series fetch is fast; a wide backfill less so."
  type        = number
  default     = 120
}

variable "memory_mb" {
  description = "Function memory. A single series is small; 256 MB is comfortable."
  type        = number
  default     = 256
}

variable "log_retention_days" {
  description = "CloudWatch log retention for the function."
  type        = number
  default     = 14
}
