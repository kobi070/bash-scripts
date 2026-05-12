# aws_scripts

This directory contains scripts for automating **AWS** operations, primarily focused on S3 and CLI management.

## 📜 Scripts Overview

1. **aws_s3_sync.sh**
   Syncs a local directory with an S3 bucket. Supports optional `--delete` and `--dryrun` flags to match AWS CLI behavior.

## 🚀 Usage

```bash
chmod +x aws_s3_sync.sh
./aws_s3_sync.sh <local_path> <s3_bucket_path>
```

✅ Prerequisites

- AWS CLI installed and configured (`aws configure`).
- Appropriate IAM permissions for S3 operations.

📘 Notes
- Ensure your AWS region is correctly set in your environment or AWS config file.
