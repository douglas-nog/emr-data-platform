output "state_bucket_name" {
  description = "Bucket that stores Terraform state for all stacks."
  value       = aws_s3_bucket.tfstate.id
}

output "backend_config" {
  description = "Values to feed into backend.hcl."
  value = {
    bucket = aws_s3_bucket.tfstate.id
    region = data.aws_region.current.region
  }
}
