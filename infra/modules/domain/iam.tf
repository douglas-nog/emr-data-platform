# EMR Serverless assumes this role to run jobs for this domain. The SourceArn
# condition scopes the trust to applications in this account only.
data "aws_iam_policy_document" "emr_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["emr-serverless.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:emr-serverless:${local.region}:${local.account_id}:/applications/*"]
    }
  }
}

resource "aws_iam_role" "emr_exec" {
  name               = "${var.project}-emr-${var.domain}-${var.env}-role"
  assume_role_policy = data.aws_iam_policy_document.emr_assume.json
}

# This policy is the technical boundary between domains: it grants access to
# this domain's buckets and databases only. A job in another domain physically
# cannot read these paths.
data "aws_iam_policy_document" "emr_exec" {
  statement {
    sid     = "ListOwnBuckets"
    effect  = "Allow"
    actions = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [
      for name in values(local.bucket_names) : "arn:aws:s3:::${name}"
    ]
  }

  statement {
    sid     = "ReadWriteOwnObjects"
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [
      for name in values(local.bucket_names) : "arn:aws:s3:::${name}/*"
    ]
  }

  statement {
    sid       = "WriteLogs"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${var.logs_bucket}",
      "arn:aws:s3:::${var.logs_bucket}/*",
    ]
  }

  statement {
    sid    = "GlueOwnDatabases"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:CreateTable",
      "glue:GetTable",
      "glue:GetTables",
      "glue:UpdateTable",
      "glue:DeleteTable",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:BatchCreatePartition",
      "glue:BatchGetPartition",
      "glue:CreatePartition",
      "glue:UpdatePartition",
      "glue:DeletePartition",
    ]
    resources = concat(
      ["arn:aws:glue:${local.region}:${local.account_id}:catalog"],
      [
        for layer in local.table_layers :
        "arn:aws:glue:${local.region}:${local.account_id}:database/${var.domain}_${layer}_${var.env}"
      ],
      [
        for layer in local.table_layers :
        "arn:aws:glue:${local.region}:${local.account_id}:table/${var.domain}_${layer}_${var.env}/*"
      ],
    )
  }
}

resource "aws_iam_role_policy" "emr_exec" {
  name   = "${var.project}-emr-${var.domain}-${var.env}-policy"
  role   = aws_iam_role.emr_exec.id
  policy = data.aws_iam_policy_document.emr_exec.json
}