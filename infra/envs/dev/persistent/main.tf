module "platform" {
  source = "../../../modules/platform"

  project = var.project
  env     = var.env
  lakeformation_admin_arn = var.lakeformation_admin_arn
}

# First domain. The module is parameterized, so `fundos` will be a second
# instance of this same block in v7 — that second instantiation is what proves
# the module is genuinely reusable.
module "macro" {
  source = "../../../modules/domain"

  project          = var.project
  env              = var.env
  domain           = "macro"
  logs_bucket      = module.platform.logs_bucket
  artifacts_bucket = module.platform.artifacts_bucket
}

module "macro_ingestion" {
  source = "../../../modules/ingestion"

  project        = var.project
  env            = var.env
  domain         = "macro"
  landing_bucket = module.macro.buckets["landing"]

  source_dir = "${path.root}/../../../../jobs/ingestion/src"
  layer_zip  = "${path.root}/../../../../jobs/ingestion/layer/layer.zip"
}