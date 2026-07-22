variable "project" {
  description = "Project short name, used as the resource name prefix."
  type        = string
}

variable "env" {
  description = "Environment name (dev, hom, prod)."
  type        = string
}

variable "domain" {
  description = "Domain name. Becomes the bucket and database prefix."
  type        = string
}

variable "logs_bucket" {
  description = "Platform logs bucket the execution role may write to."
  type        = string
}