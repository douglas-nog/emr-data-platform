output "logs_bucket" {
  description = "Bucket for Glue job logs and Spark event logs."
  value       = aws_s3_bucket.logs.id
}

output "artifacts_bucket" {
  description = "Bucket holding job code and table configs."
  value       = aws_s3_bucket.artifacts.id
}