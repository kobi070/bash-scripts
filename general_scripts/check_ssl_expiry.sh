#!/bin/bash

# Script to check the expiration date of an SSL certificate for a given domain.
# Useful for monitoring and preventing service outages due to expired certificates.
# Usage: ./check_ssl_expiry.sh <domain> [port] [days_threshold]
# Example: ./check_ssl_expiry.sh google.com 443 30

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <domain> [port] [days_threshold]"
    echo "  domain: The domain to check"
    echo "  port: (optional) The port. Default: 443"
    echo "  days_threshold: (optional) Warn if expiry is within this many days. Default: 30"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
if ! command -v openssl &> /dev/null; then
    echo "Error: openssl is not installed or not in PATH."
    exit 1
fi

# Input validation
if [ "$#" -lt 1 ]; then
    usage
fi

DOMAIN=$1
PORT=${2:-443}
THRESHOLD_DAYS=${3:-30}

# Security check: Ensure PORT and THRESHOLD_DAYS are numeric integers to prevent shell arithmetic injection
if [[ ! "$PORT" =~ ^[0-9]+$ ]]; then
    echo "Error: PORT must be a positive numeric integer."
    exit 1
fi

if [[ ! "$THRESHOLD_DAYS" =~ ^[0-9]+$ ]]; then
    echo "Error: THRESHOLD_DAYS must be a positive numeric integer."
    exit 1
fi

echo "Checking SSL certificate for $DOMAIN:$PORT..."

# Get expiry date using openssl
# Optimized: use a single awk command to extract the date, reducing process forks (grep|cut -> awk)
EXPIRY_DATE_STR=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:$PORT" 2>/dev/null | openssl x509 -noout -dates | awk -F= '/notAfter/ {print $2}')

if [ -z "$EXPIRY_DATE_STR" ]; then
    echo "Error: Could not retrieve SSL certificate for $DOMAIN:$PORT."
    exit 1
fi

# Convert dates to seconds since epoch
EXPIRY_DATE_EPOCH=$(date -d "$EXPIRY_DATE_STR" +%s)
CURRENT_DATE_EPOCH=$(date +%s)
THRESHOLD_SECONDS=$((THRESHOLD_DAYS * 24 * 3600))

DAYS_REMAINING=$(( (EXPIRY_DATE_EPOCH - CURRENT_DATE_EPOCH) / 86400 ))

echo "Expiry Date: $EXPIRY_DATE_STR"
echo "Days remaining: $DAYS_REMAINING"

if [ "$EXPIRY_DATE_EPOCH" -lt "$CURRENT_DATE_EPOCH" ]; then
    echo "CRITICAL: Certificate for $DOMAIN has EXPIRED!"
    exit 2
elif [ "$((EXPIRY_DATE_EPOCH - CURRENT_DATE_EPOCH))" -lt "$THRESHOLD_SECONDS" ]; then
    echo "WARNING: Certificate for $DOMAIN expires in $DAYS_REMAINING days (threshold: $THRESHOLD_DAYS days)."
    exit 1
else
    echo "OK: Certificate for $DOMAIN is valid for $DAYS_REMAINING days."
    exit 0
fi
