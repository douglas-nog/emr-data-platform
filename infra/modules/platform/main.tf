data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "${var.project}-platform"

  logs_bucket_name = format(
    "%s-logs-%s-%s-%s-an",
    local.name_prefix,
    var.env,
    data.aws_caller_identity.current.account_id,
    data.aws_region.current.region
  )
}

# Job logs and Spark event logs. Shared by every domain in this environment.
resource "aws_s3_bucket" "logs" {
  # checkov:skip=CKV_AWS_145:AES256 is deliberate. Logs contain no sensitive data
  # and a customer-managed key would add cost without adding control.
  # checkov:skip=CKV_AWS_144:Cross-region replication is not required for logs.
  # checkov:skip=CKV_AWS_18:Access logging on a log bucket would be recursive.
  # checkov:skip=CKV2_AWS_62:No event consumers exist for this bucket.
  # checkov:skip=CKV_AWS_21:Versioning would multiply cost for append-only logs.
  bucket = local.logs_bucket_name

  bucket_namespace = "account-regional"
  force_destroy    = true
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Logs are diagnostic, not archival. Expiring them keeps storage cost flat.
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.log_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_emrserverless_application" "spark" {
  name          = "${var.project}-spark-${var.env}"
  release_label = var.emr_release_label
  type          = "SPARK"

  # Start on job submission, so nothing is billed while idle.
  auto_start_configuration {
    enabled = true
  }

  # Safety net against a forgotten interactive session. This is independent of
  # any teardown logic in the orchestrator.
  auto_stop_configuration {
    enabled              = true
    idle_timeout_minutes = var.emr_idle_timeout_minutes
  }

  # Hard ceiling on what a runaway job can allocate.
  maximum_capacity {
    cpu    = var.emr_max_cpu
    memory = var.emr_max_memory
  }

  scheduler_configuration {
    max_concurrent_runs   = var.emr_max_concurrent_runs
    queue_timeout_minutes = var.emr_queue_timeout_minutes
  }
}