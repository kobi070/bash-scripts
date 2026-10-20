# TODO: declare module resources here.
#
# Conventions:
#   - Name the single primary resource of a type `this` (e.g., aws_iam_role.this).
#   - Prefer `for_each` over `count` for collections — for_each keys are stable,
#     count reorders/destroys resources when list items shift. Use `count` only
#     for conditional creation of a single resource: count = var.create_x ? 1 : 0.
#   - lifecycle:
#       * prevent_destroy = true on stateful critical resources
#         (databases, state buckets, KMS keys).
#       * ignore_changes only with a comment explaining why
#         (e.g., autoscaling-managed desired_count).
#   - NEVER put `provider` or `backend` blocks in a reusable module —
#     providers are configured in root modules only.
#   - Split this file by concern (iam.tf, network.tf, ...) past ~200-300 lines.
#
# Skeleton example:
#
# resource "aws_s3_bucket" "this" {
#   bucket = "${local.name_prefix}-artifacts"
#
#   tags = merge(local.common_tags, {
#     Name = "${local.name_prefix}-artifacts"
#   })
#
#   lifecycle {
#     prevent_destroy = true
#   }
# }
