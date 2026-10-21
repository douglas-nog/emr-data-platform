output "buckets" {
  description = "Bucket name per layer."
  value       = local.bucket_names
}

output "databases" {
  description = "Glue database name per table layer."
  value       = { for k, v in aws_glue_catalog_database.layer : k => v.name }
}

output "glue_execution_role_arn" {
  description = "Role Glue assumes to run jobs for this domain."
  value       = aws_iam_role.glue_exec.arn
}