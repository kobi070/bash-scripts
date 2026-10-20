variable "bucket_name" {
  description = "Globally unique name of the S3 bucket."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be 3-63 characters, lowercase letters, numbers, dots and hyphens, starting and ending with a letter or number."
  }
}

variable "project" {
  description = "Project name used for tagging."
  type        = string
  nullable    = false
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Team or person responsible for the bucket, used for tagging."
  type        = string
  nullable    = false
}

variable "enable_versioning" {
  description = "Whether to enable object versioning on the bucket."
  type        = bool
  default     = true
  nullable    = false
}

variable "force_destroy" {
  description = "Allow Terraform to destroy the bucket even when it contains objects. Use with care."
  type        = bool
  default     = false
  nullable    = false
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used for SSE-KMS encryption. When null, SSE-S3 (AES256) is used."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags merged on top of the common tags."
  type        = map(string)
  default     = {}
  nullable    = false
}
