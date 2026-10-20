# In real projects, pin the module source to a tag or registry version, e.g.:
#   source = "git::https://git.example.com/infra/modules.git//s3_bucket?ref=v1.0.0"
module "artifacts_bucket" {
  source = "../../../modules/s3_bucket"

  bucket_name       = var.bucket_name
  project           = var.project
  environment       = var.environment
  owner             = var.owner
  enable_versioning = var.enable_versioning
  tags              = local.common_tags
}
