# s3_bucket

> **Note:** This README is hand-written in terraform-docs style. Regenerating it with
> [terraform-docs](https://terraform-docs.io/) (`terraform-docs markdown table .`) is recommended
> whenever the module interface changes.

Reusable, secure-by-default S3 bucket module:

- Versioning enabled by default
- Server-side encryption (SSE-KMS when `kms_key_arn` is set, otherwise SSE-S3/AES256)
- All public access blocked
- Bucket policy denying non-TLS (`aws:SecureTransport = false`) access
- Mandatory tags (`Project`, `Environment`, `Owner`, `ManagedBy`) merged with caller tags

No `provider` or `backend` blocks — configure those in the root module.

## Usage

```hcl
module "artifacts" {
  source = "git::https://example.com/infra/modules.git//s3_bucket?ref=v1.0.0"

  bucket_name = "my-project-dev-artifacts"
  project     = "my-project"
  environment = "dev"
  owner       = "platform-team"

  enable_versioning = true
  force_destroy     = false
  kms_key_arn       = null # SSE-S3 (AES256)

  tags = {
    CostCenter = "1234"
  }
}
```

See [examples/basic](examples/basic/) for a complete working example.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10, < 2.0 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bucket_name | Globally unique name of the S3 bucket. | `string` | n/a | yes |
| project | Project name used for tagging. | `string` | n/a | yes |
| environment | Deployment environment (dev, staging, prod). | `string` | n/a | yes |
| owner | Team or person responsible for the bucket, used for tagging. | `string` | n/a | yes |
| enable_versioning | Whether to enable object versioning on the bucket. | `bool` | `true` | no |
| force_destroy | Allow Terraform to destroy the bucket even when it contains objects. | `bool` | `false` | no |
| kms_key_arn | ARN of the KMS key for SSE-KMS. When `null`, SSE-S3 (AES256) is used. | `string` | `null` | no |
| tags | Additional tags merged on top of the common tags. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | Name (ID) of the S3 bucket. |
| bucket_arn | ARN of the S3 bucket. |
| bucket_domain_name | Regional domain name of the S3 bucket. |

## Tests

Native `terraform test` suite with a mocked AWS provider:

```bash
terraform init -backend=false
terraform test
```
