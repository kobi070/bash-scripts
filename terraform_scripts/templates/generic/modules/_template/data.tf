# TODO: declare data sources here.
#
#   - Build IAM policies with `aws_iam_policy_document` data sources,
#     not inline JSON strings:
#
#     data "aws_iam_policy_document" "assume_role" {
#       statement {
#         actions = ["sts:AssumeRole"]
#         principals {
#           type        = "Service"
#           identifiers = ["ec2.amazonaws.com"]
#         }
#       }
#     }
#
#   - Use `data "aws_caller_identity" "current" {}` and
#     `data "aws_region" "current" {}` instead of hardcoding
#     account IDs and regions.
