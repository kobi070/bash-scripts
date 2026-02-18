#!/bin/bash
set -e

#--------------------------------
# USAGE
#--------------------------------
echo "./squash_merge.sh <BRANCH_TO_SQUASH> <MERGE_BRANCH_NAME> <COMMIT_MSG>"

# -------------------------------
# CONFIGURATION
# -------------------------------
# Source branch with multiple commits you want to squash
SOURCE_BRANCH="${1:-azure-pipelines}"

# Target branch where the squashed commit will go
TARGET_BRANCH="${2:-squash-br}"

# Commit message for the squashed commit
COMMIT_MESSAGE="${3:-Squashed commit from $SOURCE_BRANCH}"

# Remote name (default: origin)
REMOTE="${4:-origin}"

# -------------------------------
# STEP 1: Checkout target branch
# -------------------------------
echo "Checking out target branch: $TARGET_BRANCH"
git checkout $TARGET_BRANCH

# -------------------------------
# STEP 2: Make sure target branch is up to date
# -------------------------------
echo "Pulling latest changes from remote: $REMOTE/$TARGET_BRANCH"
git pull $REMOTE $TARGET_BRANCH --rebase

# -------------------------------
# STEP 3: Squash merge the source branch
# -------------------------------
echo "Squash merging branch $SOURCE_BRANCH into $TARGET_BRANCH"
git merge --squash $SOURCE_BRANCH

# -------------------------------
# STEP 4: Commit the squashed changes
# -------------------------------
echo "Committing squashed changes"
git commit -m "$COMMIT_MESSAGE"

# -------------------------------
# STEP 5: Push the target branch
# -------------------------------
echo "Pushing $TARGET_BRANCH to $REMOTE"
git push $REMOTE $TARGET_BRANCH

echo "✅ Squash merge complete: $SOURCE_BRANCH → $TARGET_BRANCH"
