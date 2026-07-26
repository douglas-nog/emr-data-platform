# ---------------------------------------------------------------------------
# Registration role: the identity Lake Formation assumes to reach this domain's
# S3 data. Scoped to this domain's buckets only, so registering macro's data
# never grants a path into another domain — the ADR-0001 boundary, enforced at
# the storage-access layer too.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "lf_registration_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lakeformation.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_iam_role" "lf_registration" {
  name               = "${var.project}-lf-register-${var.domain}-${var.env}-role"
  assume_role_policy = data.aws_iam_policy_document.lf_registration_assume.json
}

data "aws_iam_policy_document" "lf_registration" {
  statement {
    sid     = "AccessDomainBuckets"
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [
      for name in values(local.bucket_names) : "arn:aws:s3:::${name}/*"
    ]
  }

  statement {
    sid     = "ListDomainBuckets"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      for name in values(local.bucket_names) : "arn:aws:s3:::${name}"
    ]
  }
}

resource "aws_iam_role_policy" "lf_registration" {
  name   = "${var.project}-lf-register-${var.domain}-${var.env}-policy"
  role   = aws_iam_role.lf_registration.id
  policy = data.aws_iam_policy_document.lf_registration.json
}

# ---------------------------------------------------------------------------
# Register each table-layer bucket with Lake Formation. Only the Iceberg layers
# are registered — Landing is raw files, governed by IAM alone, not part of the
# catalog. use_service_linked_role = false points registration at the dedicated
# role above rather than the account-wide service-linked role.
# ---------------------------------------------------------------------------
resource "aws_lakeformation_resource" "layer" {
  for_each = toset(local.table_layers)

  arn                     = aws_s3_bucket.layer[each.key].arn
  role_arn                = aws_iam_role.lf_registration.arn
  use_service_linked_role = false

  depends_on = [aws_iam_role_policy.lf_registration]
}

# ---------------------------------------------------------------------------
# Tag each database with the taxonomy. A grant on "layer=spec" reaches the SPEC
# database because of these tags; onboarding a new table needs no new policy,
# only inheriting its database's tags.
# ---------------------------------------------------------------------------
resource "aws_lakeformation_resource_lf_tags" "database" {
  for_each = aws_glue_catalog_database.layer

  database {
    name = each.value.name
  }

  lf_tag {
    key   = "domain"
    value = var.domain
  }

  lf_tag {
    key   = "layer"
    value = each.key
  }

  lf_tag {
    key   = "env"
    value = var.env
  }

  depends_on = [aws_lakeformation_resource.layer]
}

# ---------------------------------------------------------------------------
# Intra-domain grant: the domain's EMR role reads all of its own layers via a
# single domain-wide tag expression. SELECT/DESCRIBE only — never ALL, never
# DROP. This is the "bind role to table" pattern, expressed by tag. Cross-domain
# grants (v7) are declared separately as domain=<producer> AND layer=spec.
# ---------------------------------------------------------------------------
resource "aws_lakeformation_permissions" "emr_domain_read" {
  principal   = aws_iam_role.emr_exec.arn
  permissions = ["SELECT", "DESCRIBE"]

  lf_tag_policy {
    resource_type = "TABLE"

    expression {
      key    = "domain"
      values = [var.domain]
    }
  }

  depends_on = [aws_lakeformation_resource_lf_tags.database]
}

# The domain role also needs DESCRIBE on the databases themselves to resolve
# them, not just the tables within.
resource "aws_lakeformation_permissions" "emr_domain_db" {
  principal   = aws_iam_role.emr_exec.arn
  permissions = ["DESCRIBE"]

  lf_tag_policy {
    resource_type = "DATABASE"

    expression {
      key    = "domain"
      values = [var.domain]
    }
  }

  depends_on = [aws_lakeformation_resource_lf_tags.database]
}