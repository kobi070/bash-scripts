# aws_scripts

This directory contains scripts for automating **AWS** operations, primarily focused on S3 and CLI management.
## 📖 Overview
This directory contains scripts for automating **AWS** operations, primarily focused on S3 and CLI management. These scripts are designed to be used in both local development and CI/CD environments.

## 📜 Scripts Overview

1. **aws_s3_sync.sh**
   Syncs a local directory with an S3 bucket. Supports optional `--delete` and `--dryrun` flags to match AWS CLI behavior.

## 🚀 Usage

2. **aws_find_unused_ebs.sh**
   Lists AWS EBS volumes that are in 'available' state (not attached to any instance).

3. **aws_list_iam_users_last_login.sh**
   Lists IAM users and their last password usage or access key usage to identify stale accounts.
3. **aws_secret_rotation_check.sh**
   Identifies unrotated or stale secrets in AWS Secrets Manager.
3. **aws_iam_key_age.sh**
   Identifies IAM access keys older than a specified number of days (default 90).

## 🚀 Usage

### Sync local directory to S3
```bash
chmod +x aws_s3_sync.sh
./aws_s3_sync.sh <local_path> <s3_bucket_path>
```

### List IAM User Activity
```bash
./aws_list_iam_users_last_login.sh
```

### Check Secret Rotation
```bash
./aws_secret_rotation_check.sh 90
```

✅ Prerequisites
## ✅ Prerequisites

- AWS CLI installed and configured (`aws configure`).
- Appropriate IAM permissions for S3 operations.

📘 Notes
## 📘 Notes
- Ensure your AWS region is correctly set in your environment or AWS config file.
