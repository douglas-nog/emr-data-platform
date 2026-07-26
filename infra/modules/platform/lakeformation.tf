# Lake Formation administrator. Without an explicit admin, even an IAM admin
# cannot create LF-Tags or grants — the provisioning itself would fail. This
# names the role Terraform runs as, so it can manage tags and permissions.
#
# admin_arns is authoritative: this block defines the FULL set of Data Lake
# administrators. Anything not listed here loses admin, so keep it complete.
resource "aws_lakeformation_data_lake_settings" "this" {
  admins = [var.lakeformation_admin_arn]

  # Keep IAMAllowedPrincipals in the default permissions for now, so existing
  # IAM-based access (EMR, Lambda) keeps working. Removing this is the explicit
  # final step of the strict-mode switch, done only after grants are in place.
  create_database_default_permissions {
    principal   = "IAM_ALLOWED_PRINCIPALS"
    permissions = ["ALL"]
  }

  create_table_default_permissions {
    principal   = "IAM_ALLOWED_PRINCIPALS"
    permissions = ["ALL"]
  }
}

# The LF-Tag taxonomy: account-level key/value definitions consumed by every
# domain. Defined once here; domains apply values, never create new keys. This
# is what makes onboarding a new domain or table cheap — the vocabulary already
# exists, only the assignment is new.
resource "aws_lakeformation_lf_tag" "domain" {
  key    = "domain"
  values = var.domains

  # Ensure the admin exists before creating tags, or the call is unauthorized.
  depends_on = [aws_lakeformation_data_lake_settings.this]
}

resource "aws_lakeformation_lf_tag" "layer" {
  key    = "layer"
  values = ["landing", "sor", "sot", "spec"]

  depends_on = [aws_lakeformation_data_lake_settings.this]
}

resource "aws_lakeformation_lf_tag" "env" {
  key    = "env"
  values = var.environments

  depends_on = [aws_lakeformation_data_lake_settings.this]
}
