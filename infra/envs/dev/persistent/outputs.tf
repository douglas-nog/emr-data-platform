output "logs_bucket" {
  description = "Bucket for Glue job logs and Spark event logs."
  value       = module.platform.logs_bucket
}

output "macro_buckets" {
  description = "Bucket name per layer for the macro domain."
  value       = module.macro.buckets
}

output "macro_databases" {
  description = "Glue database name per table layer for the macro domain."
  value       = module.macro.databases
}

output "macro_glue_role_arn" {
  description = "Execution role Glue assumes for macro jobs."
  value       = module.macro.glue_execution_role_arn
}

output "macro_ingestion_function" {
  description = "Lambda function name for macro ingestion."
  value       = module.macro_ingestion.function_name
}
