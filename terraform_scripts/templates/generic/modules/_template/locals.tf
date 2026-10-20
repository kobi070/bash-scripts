locals {
  # TODO: add a name_prefix and build all resource names from it, e.g.:
  #   name_prefix = "${var.project}-${var.environment}"
  # then use "${local.name_prefix}-<role>" in resource names/tags.

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
