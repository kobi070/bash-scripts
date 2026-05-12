#!/bin/bash

# Script to create a timestamped compressed backup of a directory.
# Includes basic rotation logic to keep only the latest N backups.
# Usage: ./backup_dir.sh <source_dir> <backup_destination> [retention_count]
# Example: ./backup_dir.sh /home/user/data /backups 7

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <source_dir> <backup_destination> [retention_count]"
    echo "  source_dir: The directory to back up"
    echo "  backup_destination: Where to store the compressed backup"
    echo "  retention_count: (optional) Number of latest backups to keep. Default: 5"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Input validation
if [ "$#" -lt 2 ]; then
    usage
fi

SOURCE_DIR=$1
BACKUP_DEST=$2
RETENTION=${3:-5}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME=$(basename "$SOURCE_DIR")_backup_$TIMESTAMP.tar.gz

# Check if source exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory '$SOURCE_DIR' does not exist."
    exit 1
fi

# Create destination if it doesn't exist
mkdir -p "$BACKUP_DEST"

echo "Creating backup of '$SOURCE_DIR' to '$BACKUP_DEST/$BACKUP_NAME'..."

# Create compressed archive
tar -czf "$BACKUP_DEST/$BACKUP_NAME" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"

echo "Backup created successfully."

# Rotation logic
echo "Checking for old backups (Retention: $RETENTION)..."
# Using find with -printf '%T+ %p\n' and sort would be more robust,
# but for portability we stick to ls and handle spaces with a loop.
mapfile -t BACKUP_FILES < <(ls -1tr "$BACKUP_DEST"/*_backup_*.tar.gz 2>/dev/null || true)
FILE_COUNT=${#BACKUP_FILES[@]}

if [ "$FILE_COUNT" -gt "$RETENTION" ]; then
    REMOVE_COUNT=$((FILE_COUNT - RETENTION))
    echo "Removing $REMOVE_COUNT oldest backup(s)..."
    for (( i=0; i<REMOVE_COUNT; i++ )); do
        rm -v "${BACKUP_FILES[$i]}"
    done
else
    echo "No rotation needed. Current backup count: $FILE_COUNT"
fi

echo "Backup process completed."
