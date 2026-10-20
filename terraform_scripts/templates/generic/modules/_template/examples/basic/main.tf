# TODO: minimal working example calling this module.
# Every module should have at least one example under examples/ tested in CI.
#
# Uncomment and adapt:
#
# provider "aws" {
#   region = "eu-west-1"
# }
#
# module "example" {
#   source = "../../"
#
#   project     = "demo"
#   environment = "dev"
# }
#
# output "example" {
#   description = "TODO: surface a useful module output."
#   value       = module.example
# }

terraform {
  required_version = ">= 1.10, < 2.0"
}
