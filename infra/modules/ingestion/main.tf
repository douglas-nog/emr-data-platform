# Package the function source at apply time. The code is pure Python with no
# compiled dependencies, so zipping on the host is safe — unlike the layer,
# which must be built in the Lambda runtime image (see layer/build.sh).
data "archive_file" "code" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/build/code.zip"
  excludes    = ["**/__pycache__/**", "**/*.pyc"]
}

# The layer holds third-party dependencies (requests), pre-built for arm64.
# source_code_hash triggers republishing only when the zip content changes.
resource "aws_lambda_layer_version" "deps" {
  layer_name          = "${var.project}-${var.domain}-ingestion-deps-${var.env}"
  filename            = var.layer_zip
  source_code_hash    = filebase64sha256(var.layer_zip)
  compatible_runtimes = [var.runtime]

  compatible_architectures = [var.architecture]
}

# Created explicitly so retention is enforced. Letting the function create its
# own group would leave logs with no expiration — a silent cost.
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "ingestion" {
  function_name = local.function_name
  role          = aws_iam_role.lambda.arn
  handler       = var.handler
  runtime       = var.runtime
  architectures = [var.architecture]

  filename         = data.archive_file.code.output_path
  source_code_hash = data.archive_file.code.output_base64sha256

  layers = [aws_lambda_layer_version.deps.arn]

  timeout     = var.timeout_seconds
  memory_size = var.memory_mb

  environment {
    variables = {
      LANDING_BUCKET = var.landing_bucket
    }
  }

  # Ensure the log group exists before the function, so the first invocation
  # writes into the retention-bound group rather than creating its own.
  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy.lambda,
  ]
}
