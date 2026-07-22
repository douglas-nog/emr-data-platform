module "platform" {
  source = "../../../modules/platform"

  project = var.project
  env     = var.env
}