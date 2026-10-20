# No credentials here — rely on the ambient AWS auth chain
# (environment variables, shared config/SSO profile, or instance/IRSA role).
#
# For cross-account deployments, add an assume_role block:
#   assume_role {
#     role_arn = "arn:aws:iam::<ACCOUNT_ID>:role/terraform-deploy"
#   }
provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}
