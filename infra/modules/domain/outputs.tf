output "buckets" {
  description = "Bucket name per layer."
  value       = local.bucket_names
}

output "databases" {
  description = "Glue database name per table layer."
  value       = { for k, v in aws_glue_catalog_database.layer : k => v.name }
}

output "emr_execution_role_arn" {
  description = "Role EMR Serverless assumes to run jobs for this domain."
  value       = aws_iam_role.emr_exec.arn
}