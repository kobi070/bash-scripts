variable "region" {
  description = "AWS region to deploy resources into."
  type        = string
}

variable "project" {
  description = "Project name used for naming and tagging."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, or prod)."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Team or person responsible for this stack."
  type        = string
}

variable "bucket_name" {
  description = "Globally unique name of the artifacts S3 bucket."
  type        = string
}

variable "enable_versioning" {
  description = "Whether to enable versioning on the artifacts bucket."
  type        = bool
}
