output "function_name" {
  description = "Lambda function name, used to invoke it (CLI now, Airflow later)."
  value       = aws_lambda_function.ingestion.function_name
}

output "function_arn" {
  description = "Lambda function ARN."
  value       = aws_lambda_function.ingestion.arn
}

output "layer_arn" {
  description = "Published layer version ARN, reusable by sibling connectors."
  value       = aws_lambda_layer_version.deps.arn
}
