# Reusable modules declare the MINIMUM compatible provider version (>= X.0).
# Root modules decide the upper bound and pin with the pessimistic
# constraint (~> X.Y) plus a committed .terraform.lock.hcl.
terraform {
  required_version = ">= 1.10, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
