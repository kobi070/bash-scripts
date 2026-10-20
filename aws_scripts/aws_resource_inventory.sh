#!/bin/bash

# Script to inventory AWS resources in an account.
# Default mode uses the Resource Groups Tagging API to list ALL taggable
# resources, grouped by service. Per-service mode uses native CLI calls
# for richer details on selected services.
# Usage: ./aws_resource_inventory.sh [--all] [--services <svc1,svc2,...>] [--region <region>] [--profile <profile>] [--output <table|json>]
# Example: ./aws_resource_inventory.sh --all
# Example: ./aws_resource_inventory.sh --services ec2,s3,iam --region us-east-1

set -euo pipefail

SUPPORTED_SERVICES="ec2 s3 iam rds lambda vpc ebs sg elb eks"

usage() {
    echo "Usage: $0 [--all] [--services <svc1,svc2,...>] [--region <region>] [--profile <profile>] [--output <table|json>]"
    echo ""
    echo "Options:"
    echo "  --all                 Inventory ALL taggable resources via the Resource Groups Tagging API (default)."
    echo "  --services <list>     Comma-separated list of services to inventory with native CLI calls."
    echo "                        Supported: ${SUPPORTED_SERVICES// /, }"
    echo "  --region <region>     AWS region to query. Default: current AWS CLI config."
    echo "  --profile <profile>   AWS CLI profile to use. Default: current AWS CLI config."
    echo "  --output <format>     Output format: table (default) or json."
    echo "  -h, --help            Show this help message."
    echo ""
    echo "Examples:"
    echo "  $0 --all"
    echo "  $0 --services ec2,s3 --region eu-west-1 --output json"
    exit 1
}

# Check for required tools
for tool in aws jq; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: $tool is not installed or not in PATH."
        exit 1
    fi
done

MODE="all"
SERVICES=""
OUTPUT="table"
AWS_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --all)
            MODE="all"
            shift
            ;;
        --services)
            [[ -n "${2:-}" ]] || { echo "Error: --services requires a value."; usage; }
            MODE="services"
            SERVICES="$2"
            shift 2
            ;;
        --region)
            [[ -n "${2:-}" ]] || { echo "Error: --region requires a value."; usage; }
            AWS_ARGS+=(--region "$2")
            shift 2
            ;;
        --profile)
            [[ -n "${2:-}" ]] || { echo "Error: --profile requires a value."; usage; }
            AWS_ARGS+=(--profile "$2")
            shift 2
            ;;
        --output)
            [[ -n "${2:-}" ]] || { echo "Error: --output requires a value."; usage; }
            OUTPUT="$2"
            [[ "$OUTPUT" == "table" || "$OUTPUT" == "json" ]] || { echo "Error: --output must be 'table' or 'json'."; usage; }
            shift 2
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

# Wrapper to keep AWS_ARGS expansion safe under 'set -u' with empty arrays.
awscli() {
    if [[ ${#AWS_ARGS[@]} -gt 0 ]]; then
        aws "${AWS_ARGS[@]}" "$@"
    else
        aws "$@"
    fi
}

print_header() {
    echo "===================================================================================================="
    echo "$1"
    echo "===================================================================================================="
}

inventory_all() {
    print_header "AWS Resource Inventory (Resource Groups Tagging API)"
    local resources
    resources=$(awscli resourcegroupstaggingapi get-resources --output json \
        --query 'ResourceTagMappingList[].ResourceARN')

    if [[ "$OUTPUT" == "json" ]]; then
        echo "$resources" | jq '[ .[] | {arn: ., service: (split(":")[2])} ] | group_by(.service) | map({service: .[0].service, count: length, resources: [.[].arn]})'
        return
    fi

    echo "$resources" | jq -r '
        [ .[] | {arn: ., service: (split(":")[2])} ]
        | group_by(.service)
        | sort_by(-length)
        | .[]
        | "\(.[0].service)\t\(length)" as $summary
        | ($summary, (.[] | "  \(.arn)"))
    ' | while IFS= read -r line; do
        if [[ "$line" == "  "* ]]; then
            echo "$line"
        else
            printf "\n%-30s (count: %s)\n" "$(echo "$line" | cut -f1)" "$(echo "$line" | cut -f2)"
        fi
    done

    local total
    total=$(echo "$resources" | jq 'length')
    echo ""
    echo "Total taggable resources found: $total"
    echo "Note: the Tagging API only returns taggable resources; use --services for deeper per-service detail."
}

inventory_service() {
    local svc="$1"
    case "$svc" in
        ec2)
            print_header "EC2 Instances"
            awscli ec2 describe-instances --output "$OUTPUT" \
                --query 'Reservations[].Instances[].{ID:InstanceId,Type:InstanceType,State:State.Name,Name:Tags[?Key==`Name`]|[0].Value,PrivateIP:PrivateIpAddress,PublicIP:PublicIpAddress}'
            ;;
        s3)
            print_header "S3 Buckets"
            awscli s3api list-buckets --output "$OUTPUT" \
                --query 'Buckets[].{Name:Name,Created:CreationDate}'
            ;;
        iam)
            print_header "IAM Users"
            awscli iam list-users --output "$OUTPUT" \
                --query 'Users[].{User:UserName,Created:CreateDate,PasswordLastUsed:PasswordLastUsed}'
            print_header "IAM Roles"
            awscli iam list-roles --output "$OUTPUT" \
                --query 'Roles[].{Role:RoleName,Created:CreateDate}'
            ;;
        rds)
            print_header "RDS Instances"
            awscli rds describe-db-instances --output "$OUTPUT" \
                --query 'DBInstances[].{ID:DBInstanceIdentifier,Engine:Engine,Class:DBInstanceClass,Status:DBInstanceStatus,MultiAZ:MultiAZ}'
            ;;
        lambda)
            print_header "Lambda Functions"
            awscli lambda list-functions --output "$OUTPUT" \
                --query 'Functions[].{Name:FunctionName,Runtime:Runtime,Memory:MemorySize,LastModified:LastModified}'
            ;;
        vpc)
            print_header "VPCs"
            awscli ec2 describe-vpcs --output "$OUTPUT" \
                --query 'Vpcs[].{ID:VpcId,CIDR:CidrBlock,Default:IsDefault,State:State}'
            print_header "Subnets"
            awscli ec2 describe-subnets --output "$OUTPUT" \
                --query 'Subnets[].{ID:SubnetId,VPC:VpcId,CIDR:CidrBlock,AZ:AvailabilityZone}'
            ;;
        ebs)
            print_header "EBS Volumes"
            awscli ec2 describe-volumes --output "$OUTPUT" \
                --query 'Volumes[].{ID:VolumeId,Size:Size,Type:VolumeType,State:State,Encrypted:Encrypted}'
            ;;
        sg)
            print_header "Security Groups"
            awscli ec2 describe-security-groups --output "$OUTPUT" \
                --query 'SecurityGroups[].{ID:GroupId,Name:GroupName,VPC:VpcId,Description:Description}'
            ;;
        elb)
            print_header "Load Balancers (ELBv2)"
            awscli elbv2 describe-load-balancers --output "$OUTPUT" \
                --query 'LoadBalancers[].{Name:LoadBalancerName,Type:Type,Scheme:Scheme,State:State.Code,DNS:DNSName}'
            ;;
        eks)
            print_header "EKS Clusters"
            awscli eks list-clusters --output "$OUTPUT" --query 'clusters'
            ;;
        *)
            echo "Warning: unsupported service '$svc' (supported: ${SUPPORTED_SERVICES// /, }). Skipping."
            return 1
            ;;
    esac
}

if [[ "$MODE" == "all" ]]; then
    inventory_all
else
    FAILED=0
    IFS=',' read -ra SVC_LIST <<< "$SERVICES"
    for svc in "${SVC_LIST[@]}"; do
        svc=$(echo "$svc" | tr '[:upper:]' '[:lower:]' | xargs)
        [[ -n "$svc" ]] || continue
        inventory_service "$svc" || FAILED=$((FAILED + 1))
    done
    if [[ "$FAILED" -gt 0 ]]; then
        echo ""
        echo "Completed with $FAILED skipped/unsupported service(s)."
    fi
fi
