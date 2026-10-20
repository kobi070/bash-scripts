mock_provider "aws" {}

variables {
  bucket_name = "test-project-dev-bucket"
  project     = "test-project"
  environment = "dev"
  owner       = "platform-team"
}

run "versioning_enabled" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "Bucket versioning must be enabled by default."
  }
}

run "public_access_blocked" {
  command = plan

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.this.block_public_acls,
      aws_s3_bucket_public_access_block.this.block_public_policy,
      aws_s3_bucket_public_access_block.this.ignore_public_acls,
      aws_s3_bucket_public_access_block.this.restrict_public_buckets,
    ])
    error_message = "All four public access block settings must be true."
  }
}

run "encryption_configured" {
  command = plan

  assert {
    # "rule" is a set, so it cannot be indexed — flatten algorithms with a for expression.
    condition = contains(
      flatten([
        for r in aws_s3_bucket_server_side_encryption_configuration.this.rule :
        [for d in r.apply_server_side_encryption_by_default : d.sse_algorithm]
      ]),
      "AES256"
    )
    error_message = "SSE-S3 (AES256) must be used when no KMS key is provided."
  }
}

run "tags_contain_managed_by" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this.tags["ManagedBy"] == "terraform"
    error_message = "Bucket tags must contain ManagedBy=terraform."
  }
}

run "invalid_environment_rejected" {
  command = plan

  variables {
    bucket_name = "test-project-dev-bucket"
    project     = "test-project"
    environment = "production"
    owner       = "platform-team"
  }

  expect_failures = [var.environment]
}
