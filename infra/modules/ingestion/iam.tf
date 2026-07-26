data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  function_name = "${var.project}-${var.domain}-ingestion-${var.env}"
}

data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${local.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

# Scoped to this domain's Landing bucket only. The function cannot touch any
# other domain's data — the same boundary the EMR role enforces.
data "aws_iam_policy_document" "lambda" {
  statement {
    sid     = "WriteLanding"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${var.landing_bucket}/*"]
  }

  statement {
    sid    = "WriteOwnLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.function_name}:*",
    ]
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${local.function_name}-policy"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda.json
}
