# Remote state backend — PLACEHOLDER values, replace before use.
# Backend blocks cannot reference variables; values must be literals.
#
# Alternative: keep this block empty (backend "s3" {}) and supply values via
# partial configuration:
#   terraform init -backend-config=env/dev.s3.tfbackend
#
# State is SENSITIVE — it may contain secrets in plaintext. Restrict read
# access to the state bucket as tightly as write access.
terraform {
  backend "s3" {
    bucket       = "CHANGE-ME-org-tfstate-dev"
    key          = "example-stack/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}
