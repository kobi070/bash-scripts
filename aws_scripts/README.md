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

### Audit Resource Tags
```bash
./aws_resource_tag_audit.sh us-east-1
```

## ✅ Prerequisites

- AWS CLI installed and configured (`aws configure`).
- Appropriate IAM permissions for the operations being performed.

## 📘 Notes
- Ensure your AWS region is correctly set in your environment or AWS config file.
