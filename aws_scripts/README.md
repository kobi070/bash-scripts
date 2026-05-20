# aws_scripts

This directory contains scripts for automating **AWS** operations, focused on security audit, resource management, and S3.

## 📖 Overview
These scripts are designed for both local development and CI/CD environments to ensure secure and efficient AWS resource management.

## 📜 Scripts Overview

1. **aws_s3_sync.sh**: Robust S3 synchronization with support for delete and dry-run flags.
2. **aws_find_unused_ebs.sh**: Lists AWS EBS volumes that are in 'available' state.
3. **aws_sg_audit.sh**: Audits AWS Security Groups for overly permissive rules (0.0.0.0/0).
4. **aws_iam_admin_audit.sh**: Identifies IAM users and groups with `AdministratorAccess` policies.
5. **aws_list_iam_users_last_login.sh**: Lists IAM users and their last activity to identify stale accounts.
6. **aws_secret_rotation_check.sh**: Identifies unrotated or stale secrets in AWS Secrets Manager.
7. **aws_iam_key_age.sh**: Identifies IAM access keys older than a specified number of days (default 90).
8. **aws_ec2_public_ip_checker.sh**: Identifies EC2 instances with public IP addresses.
9. **aws_list_old_ebs_snapshots.sh**: Lists EBS snapshots older than X days.

## 🚀 Usage

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

## ✅ Prerequisites

- AWS CLI installed and configured (`aws configure`).
- Appropriate IAM permissions for the operations performed.
- `jq` installed for JSON processing.

## 📘 Notes
- Ensure your AWS region is correctly set in your environment or AWS config file.
