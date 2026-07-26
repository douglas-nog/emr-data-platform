data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # Landing holds raw files. The other three hold Iceberg tables and therefore
  # must never receive an S3 lifecycle expiration rule: it would delete data
  # files that table metadata still references.
  layers        = ["landing", "sor", "sot", "spec"]
  table_layers  = ["sor", "sot", "spec"]

  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region

  bucket_names = {
    for layer in local.layers :
    layer => format(
      "%s-%s-%s-%s-%s-%s-an",
      var.project, var.domain, layer, var.env, local.account_id, local.region
    )
  }
}

resource "aws_s3_bucket" "layer" {
  for_each = toset(local.layers)

  # checkov:skip=CKV_AWS_145:AES256 is deliberate. Source data is public; a
  # customer-managed key would add cost without adding control. Revisit in v11.
  # checkov:skip=CKV_AWS_144:Cross-region replication is not required.
  # checkov:skip=CKV_AWS_18:Access logging is tracked as a roadmap item (v11).
  # checkov:skip=CKV2_AWS_62:No event consumers exist yet.
  # checkov:skip=CKV_AWS_21:Iceberg snapshots provide versioning at table level.
  bucket           = local.bucket_names[each.key]
  bucket_namespace = "account-regional"

  # Teardown is brute force by design: the final destroy must leave nothing
  # behind. Per-session safety comes from stack separation, not from this flag —
  # the persistent stack is simply never destroyed during development.
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "layer" {
  for_each = aws_s3_bucket.layer

  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "layer" {
  for_each = aws_s3_bucket.layer

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Only aborts failed uploads. Expiration policies are deferred to v12 and will
# apply to Landing exclusively.
resource "aws_s3_bucket_lifecycle_configuration" "layer" {
  for_each = aws_s3_bucket.layer

  bucket = each.value.id

  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Landing has no database: raw files are not tables.
resource "aws_glue_catalog_database" "layer" {
  for_each = toset(local.table_layers)

  name        = "${var.domain}_${each.key}_${var.env}"
  description = "${var.domain} domain, ${upper(each.key)} layer, ${var.env}"
  location_uri = "s3://${local.bucket_names[each.key]}/"
}