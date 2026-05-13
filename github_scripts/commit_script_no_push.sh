#!/bin/bash
set -e
# This script will get your branch you are working on and weill generate a commit message based on the branch + the message you want to provide
# IMPORTANT NOTE: this script would be used only after you have used git add . or git add /<certain_folder/file/etc>

# Get the branch name
# Optimized: use rev-parse for direct branch detection, reducing process forks
branch=$(git rev-parse --abbrev-ref HEAD)

# Ask the user for a commit message
read -p "Enter commit message for branch $branch: " commit_message

# Check if the commit message is empty
if [ -z "$commit_message" ]; then
  echo "Commit message cannot be empty. Exiting..."
  exit 1
fi

# Get all the files in the branch you want to commit
# Optimized: use git diff --cached to directly list staged files, reducing process forks
commit_files=$(git diff --name-only --cached)

# Generate the commit message
commit_message="[${branch}] $commit_message - files: $commit_files"

# Commit the message
git commit -m "$commit_message"

# To Push the changes on your onw cli to the branch you are working on
# git push origin $branch