#!/bin/bash
# benchmark_s3_audit.sh - Benchmark the S3 tag audit performance.

set -euo pipefail

# Create temporary bin directory for mocks
MOCK_BIN=$(mktemp -d)
export PATH="$MOCK_BIN:$PATH"
export BENCHMARK_BUCKET_COUNT=50

# Cleanup on exit
trap 'rm -rf "$MOCK_BIN"' EXIT

# Create a mock aws CLI
cat <<'EOFMOCK2' > "$MOCK_BIN/aws"
#!/bin/bash
if [[ "$*" == *"s3api list-buckets"* ]]; then
    # Generate bucket names
    echo "["
    for i in $(seq 1 $BENCHMARK_BUCKET_COUNT); do
        echo "  \"bucket-$i\""
        if [ $i -lt $BENCHMARK_BUCKET_COUNT ]; then echo ","; fi
    done
    echo "]"
elif [[ "$*" == *"resourcegroupstaggingapi get-resources"* ]]; then
    # New optimized call with full JSON structure
    echo "{\"ResourceTagMappingList\": ["
    for i in $(seq 1 $BENCHMARK_BUCKET_COUNT); do
        INDEX=$i
        if [ $((INDEX % 2)) -eq 0 ]; then
             echo "{\"ResourceARN\": \"arn:aws:s3:::bucket-$i\", \"Tags\": [{\"Key\": \"Owner\", \"Value\": \"TeamA\"}, {\"Key\": \"Environment\", \"Value\": \"Prod\"}]}"
        else
             echo "{\"ResourceARN\": \"arn:aws:s3:::bucket-$i\", \"Tags\": [{\"Key\": \"Owner\", \"Value\": \"TeamA\"}]}"
        fi
        if [ $i -lt $BENCHMARK_BUCKET_COUNT ]; then echo ","; fi
    done
    echo "], \"PaginationToken\": null}"
elif [[ "$*" == *"ec2 describe-instances"* ]]; then
    echo "[]"
fi
EOFMOCK2
chmod +x "$MOCK_BIN/aws"

echo "Benchmarking S3 Tag Audit with $BENCHMARK_BUCKET_COUNT buckets..."

START_TIME=$(date +%s%N)
./aws_scripts/aws_resource_tag_audit.sh > /dev/null
END_TIME=$(date +%s%N)

DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
echo "Execution time: ${DURATION}ms"
