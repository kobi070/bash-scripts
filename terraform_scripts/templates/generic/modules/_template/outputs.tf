# TODO: declare module outputs here.
#
#   - Every output needs a `description`.
#   - Output IDs, ARNs, names, and endpoints consumers need — not whole objects.
#   - Mark outputs containing secrets `sensitive = true`.
#
# Example:
#
# output "bucket_arn" {
#   description = "ARN of the artifacts bucket."
#   value       = aws_s3_bucket.this.arn
# }
#
# output "db_password" {
#   description = "Generated database password."
#   value       = random_password.db.result
#   sensitive   = true
# }
