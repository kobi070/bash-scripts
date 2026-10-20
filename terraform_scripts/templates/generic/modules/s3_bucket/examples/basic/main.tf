terraform {
  required_version = ">= 1.10, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "eu-west-1"
}

provider "aws" {
  region = var.region
}

module "bucket" {
  source = "../../"

  bucket_name = "example-project-dev-artifacts"
  project     = "example-project"
  environment = "dev"
  owner       = "platform-team"

  tags = {
    CostCenter = "1234"
  }
}

output "bucket_id" {
  description = "Name (ID) of the created S3 bucket."
  value       = module.bucket.bucket_id
}

output "bucket_arn" {
  description = "ARN of the created S3 bucket."
  value       = module.bucket.bucket_arn
}

output "bucket_domain_name" {
  description = "Regional domain name of the created S3 bucket."
  value       = module.bucket.bucket_domain_name
}
