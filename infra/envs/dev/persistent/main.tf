module "platform" {
  source = "../../../modules/platform"

  project = var.project
  env     = var.env
}

module "macro" {
  source = "../../../modules/domain"

  project     = var.project
  env         = var.env
  domain      = "macro"
  logs_bucket = module.platform.logs_bucket
}