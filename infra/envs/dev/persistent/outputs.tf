output "emr_application_id" {
  description = "EMR Serverless application ID for submitting job runs."
  value       = module.platform.emr_application_id
}

output "logs_bucket" {
  description = "Bucket for EMR job logs and Spark event logs."
  value       = module.platform.logs_bucket
}