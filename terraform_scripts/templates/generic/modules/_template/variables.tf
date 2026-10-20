# TODO: declare module inputs.
#
# Rules for every variable:
#   - Always set `description` and `type` (use precise types, avoid `any`).
#   - Add `default` only when a sensible default exists.
#   - Add `validation` blocks for constrained inputs.
#   - Set `nullable = false` when null is never valid.
#   - Mark secret inputs `sensitive = true`.
#   - Booleans are positive and prefixed: enable_*, create_*, is_*.
#
# Example pattern:
#
# variable "subnets" {
#   description = "Map of subnet name to configuration."
#   type = map(object({
#     cidr_block = string
#     az         = string
#     public     = optional(bool, false)
#   }))
#   nullable = false
#
#   validation {
#     condition     = alltrue([for s in var.subnets : can(cidrhost(s.cidr_block, 0))])
#     error_message = "Every cidr_block must be a valid CIDR."
#   }
# }

variable "project" {
  description = "Project name, used for naming and tagging."
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
