output "bucket_arn" {
  description = "ARN of the artifacts S3 bucket."
  value       = module.artifacts_bucket.bucket_arn
}

output "bucket_id" {
  description = "Name (ID) of the artifacts S3 bucket."
  value       = module.artifacts_bucket.bucket_id
}
