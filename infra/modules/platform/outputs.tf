output "emr_application_id" {
  description = "EMR Serverless application ID, used when submitting job runs."
  value       = aws_emrserverless_application.spark.id
}

output "logs_bucket" {
  description = "Bucket for EMR job logs and Spark event logs."
  value       = aws_s3_bucket.logs.id
}