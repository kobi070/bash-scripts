#!/bin/bash

# Unified AWS audit dispatcher.
# Wraps the existing single-purpose audit scripts in this directory and runs
# one, several, or all of them, then prints a summary report.
# Usage: ./aws_audit.sh [--type <t1,t2,...>|all] [--region <region>] [--days <n>] [--list]
# Example: ./aws_audit.sh --type all
# Example: ./aws_audit.sh --type sg,iam-admin,ebs-unencrypted --region us-east-1

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Audit type -> wrapped script. Args convention per script:
#   region  -> script takes [region] positional
#   days    -> script takes [max_days] positional
#   none    -> script takes no args
#   dr      -> script takes -d <days> -r <region> flags
AUDIT_TYPES=(sg iam-admin iam-keys iam-login ebs-unused ebs-unencrypted snapshots public-ip secrets tags)

audit_script() {
    case "$1" in
        sg)              echo "aws_sg_audit.sh" ;;
        iam-admin)       echo "aws_iam_admin_audit.sh" ;;
        iam-keys)        echo "aws_iam_key_age.sh" ;;
        iam-login)       echo "aws_list_iam_users_last_login.sh" ;;
        ebs-unused)      echo "aws_find_unused_ebs.sh" ;;
        ebs-unencrypted) echo "aws_ebs_unencrypted_volumes.sh" ;;
        snapshots)       echo "aws_list_old_ebs_snapshots.sh" ;;
        public-ip)       echo "aws_ec2_public_ip_checker.sh" ;;
        secrets)         echo "aws_secret_rotation_check.sh" ;;
        tags)            echo "aws_resource_tag_audit.sh" ;;
        *)               echo "" ;;
    esac
}

audit_args_style() {
    case "$1" in
        sg|ebs-unused|ebs-unencrypted|public-ip|tags) echo "region" ;;
        iam-keys|secrets)                             echo "days" ;;
        iam-admin|iam-login)                          echo "none" ;;
        snapshots)                                    echo "dr" ;;
    esac
}

usage() {
    echo "Usage: $0 [--type <t1,t2,...>|all] [--region <region>] [--days <n>] [--list]"
    echo ""
    echo "Options:"
    echo "  --type <list>     Comma-separated audit types to run, or 'all' (default: all)."
    echo "  --region <region> AWS region passed to region-aware audits. Default: current AWS CLI config."
    echo "  --days <n>        Age threshold passed to age-aware audits (iam-keys, secrets, snapshots)."
    echo "  --list            List available audit types and exit."
    echo "  -h, --help        Show this help message."
    echo ""
    echo "Audit types:"
    for t in "${AUDIT_TYPES[@]}"; do
        printf "  %-18s -> %s\n" "$t" "$(audit_script "$t")"
    done
    exit 1
}

# Check for required tools
for tool in aws jq; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: $tool is not installed or not in PATH."
        exit 1
    fi
done

TYPES="all"
REGION=""
DAYS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --type)
            [[ -n "${2:-}" ]] || { echo "Error: --type requires a value."; usage; }
            TYPES="$2"
            shift 2
            ;;
        --region)
            [[ -n "${2:-}" ]] || { echo "Error: --region requires a value."; usage; }
            REGION="$2"
            shift 2
            ;;
        --days)
            [[ -n "${2:-}" ]] || { echo "Error: --days requires a value."; usage; }
            DAYS="$2"
            [[ "$DAYS" =~ ^[0-9]+$ ]] || { echo "Error: --days must be a positive integer."; exit 1; }
            shift 2
            ;;
        --list)
            echo "Available audit types:"
            for t in "${AUDIT_TYPES[@]}"; do
                printf "  %-18s -> %s\n" "$t" "$(audit_script "$t")"
            done
            exit 0
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Error: Unknown option: $1"
            usage
            ;;
    esac
done

if [[ "$TYPES" == "all" ]]; then
    SELECTED=("${AUDIT_TYPES[@]}")
else
    IFS=',' read -ra SELECTED <<< "$TYPES"
fi

PASSED=()
FAILED=()
SKIPPED=()

run_audit() {
    local type="$1"
    local script args_style script_path
    script=$(audit_script "$type")

    if [[ -z "$script" ]]; then
        echo "Warning: unknown audit type '$type'. Skipping."
        SKIPPED+=("$type (unknown type)")
        return
    fi

    script_path="$SCRIPT_DIR/$script"
    if [[ ! -x "$script_path" && ! -f "$script_path" ]]; then
        echo "Warning: $script not found in $SCRIPT_DIR. Skipping '$type'."
        SKIPPED+=("$type (script missing)")
        return
    fi

    args_style=$(audit_args_style "$type")
    local cmd=(bash "$script_path")
    case "$args_style" in
        region) [[ -n "$REGION" ]] && cmd+=("$REGION") ;;
        days)   [[ -n "$DAYS" ]] && cmd+=("$DAYS") ;;
        dr)
            [[ -n "$DAYS" ]] && cmd+=(-d "$DAYS")
            [[ -n "$REGION" ]] && cmd+=(-r "$REGION")
            ;;
        none)   : ;;
    esac

    echo ""
    echo "===================================================================================================="
    echo ">>> Running audit: $type ($script)"
    echo "===================================================================================================="
    if "${cmd[@]}"; then
        PASSED+=("$type")
    else
        FAILED+=("$type")
    fi
}

for type in "${SELECTED[@]}"; do
    type=$(echo "$type" | tr '[:upper:]' '[:lower:]' | xargs)
    [[ -n "$type" ]] || continue
    run_audit "$type"
done

echo ""
echo "===================================================================================================="
echo "AUDIT SUMMARY"
echo "===================================================================================================="
echo "Passed:  ${#PASSED[@]}  ${PASSED[*]:-}"
echo "Failed:  ${#FAILED[@]}  ${FAILED[*]:-}"
echo "Skipped: ${#SKIPPED[@]}  ${SKIPPED[*]:-}"

if [[ ${#FAILED[@]} -gt 0 ]]; then
    exit 1
fi
