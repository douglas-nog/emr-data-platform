data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # Account regional namespace: <prefix>-<account>-<region>-an
  state_bucket_name = format(
    "%s-tfstate-%s-%s-an",
    var.project,
    data.aws_caller_identity.current.account_id,
    data.aws_region.current.region
  )
}

resource "aws_s3_bucket" "tfstate" {
  bucket           = local.state_bucket_name
  bucket_namespace = "account-regional"

  # The state bucket must survive every destroy of every other stack.
  # Removing it is a deliberate, manual act.
  lifecycle {
    prevent_destroy = true
  }
}

# Mandatory for S3-native state locking, and the only way to recover
# a state file corrupted by a failed apply.
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# State history grows without bound. Keep 90 days of previous versions
# and clean up failed multipart uploads.
resource "aws_s3_bucket_lifecycle_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    id     = "expire-noncurrent-state-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Reject any request that does not use TLS.
resource "aws_s3_bucket_policy" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  policy = data.aws_iam_policy_document.tfstate.json
}

data "aws_iam_policy_document" "tfstate" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.tfstate.arn,
      "${aws_s3_bucket.tfstate.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}