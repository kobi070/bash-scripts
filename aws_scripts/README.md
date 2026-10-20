# aws_scripts

## 📖 Overview
This directory contains scripts for automating **AWS** operations, primarily focused on S3, IAM, and resource auditing. These scripts are designed to be used in both local development and CI/CD environments.

## 📜 Scripts Overview

1. **aws_s3_sync.sh**
   Syncs a local directory with an S3 bucket. Supports optional `--delete` and `--dryrun` flags to match AWS CLI behavior.

2. **aws_find_unused_ebs.sh**
   Lists AWS EBS volumes that are in 'available' state (not attached to any instance).

3. **aws_sg_audit.sh**
   Audits AWS Security Groups for overly permissive rules (0.0.0.0/0).

4. **aws_iam_admin_audit.sh**
   Identifies all IAM users and groups that have the `AdministratorAccess` policy directly attached.

5. **aws_list_iam_users_last_login.sh**
   Lists IAM users and their last password usage or access key usage to identify stale accounts.

6. **aws_secret_rotation_check.sh**
   Identifies unrotated or stale secrets in AWS Secrets Manager.

7. **aws_iam_key_age.sh**
   Identifies IAM access keys older than a specified number of days (default 90).

8. **aws_ec2_public_ip_checker.sh**
   Identifies EC2 instances with public IP addresses to highlight potential security exposures.

9. **aws_ebs_unencrypted_volumes.sh**
   Identifies all EBS volumes in the current region that are not encrypted.

10. **aws_list_old_ebs_snapshots.sh**
    Lists EBS snapshots older than a specified number of days.

11. **aws_resource_tag_audit.sh**
    Audits EC2 instances and S3 buckets for missing mandatory tags (e.g., 'Owner', 'Environment').

12. **aws_resource_inventory.sh**
    Inventories AWS resources. Default mode lists ALL taggable resources via the Resource Groups Tagging API grouped by service; `--services` mode runs native CLI calls for richer details on selected services (ec2, s3, iam, rds, lambda, vpc, ebs, sg, elb, eks). Supports `--region`, `--profile` and `--output table|json`.

13. **aws_audit.sh**
    Unified audit dispatcher. Runs one, several, or all of the audit scripts in this directory (`--type sg,iam-admin,...|all`), forwards `--region`/`--days` where applicable, and prints a pass/fail/skip summary. Use `--list` to see all audit types.

14. **aws_profile_manager.sh**
    Manages AWS CLI profiles: list, view (secrets masked, optional `--json`), add, edit, delete, and switch. Supports access-key, SSO, and assume-role profiles. Works interactively (menu, run with no arguments) or non-interactively via flags. Switching supports `--persist` (copies profile into `[default]`) or `--env` (prints `export AWS_PROFILE=...` for `eval`). Backs up `~/.aws/config` and `~/.aws/credentials` before any mutation; optional `--validate` runs `sts get-caller-identity`.

## 🚀 Usage examples

### Manage AWS profiles
```bash
./aws_profile_manager.sh                 # interactive menu
./aws_profile_manager.sh list
./aws_profile_manager.sh add -p dev --access-key AKIA... --secret-key xxx --region us-east-1
./aws_profile_manager.sh switch -p dev --validate
eval "$(./aws_profile_manager.sh switch -p dev --env)"   # session-only switch
```

### Inventory all resources (Tagging API)
```bash
./aws_resource_inventory.sh --all
```

### Inventory selected services with details
```bash
./aws_resource_inventory.sh --services ec2,s3,iam --region us-east-1 --output json
```

### Run all audits with a summary report
```bash
./aws_audit.sh --type all --region us-east-1
```

### Run selected audits with custom age threshold
```bash
./aws_audit.sh --type iam-keys,secrets,snapshots --days 60
```

### Sync local directory to S3
```bash
./aws_s3_sync.sh <local_path> <s3_bucket_path>
```

### Audit IAM Administrators
```bash
./aws_iam_admin_audit.sh
```

### List IAM User Activity
```bash
./aws_list_iam_users_last_login.sh
```

### Check Secret Rotation
```bash
./aws_secret_rotation_check.sh 90
```

### Check EC2 Public IPs
```bash
./aws_ec2_public_ip_checker.sh
```

### Audit Resource Tags
```bash
./aws_resource_tag_audit.sh us-east-1
```

## ✅ Prerequisites

- AWS CLI installed and configured (`aws configure`).
- Appropriate IAM permissions for the operations being performed.
- Ensure your AWS region is correctly set in your environment or AWS config file.
