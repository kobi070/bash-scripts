terraform {
  required_version = ">= 1.10, < 2.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Reusable module: declare the minimum compatible version only.
      # Root modules decide the upper bound.
      version = ">= 5.0"
    }
  }
}
