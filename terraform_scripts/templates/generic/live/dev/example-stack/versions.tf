# Root modules pin providers with a pessimistic (~>) constraint.
# In real projects, commit .terraform.lock.hcl to lock exact provider versions.
terraform {
  required_version = ">= 1.10, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
