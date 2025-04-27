#!/bin/bash
set -euo pipefail

# This script creates a command alias for the GitHub CLI (gh) to make it easier to use.
# It checks if the alias already exists, and if not, it creates it.
# Usage: ./create_command_alias.sh <alias_name> <command>
# Example: ./create_command_alias.sh myalias "gh repo list"

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <alias_name> <command>"
    exit 1
fi

# Assign arguments to variables
alias_name="$1"
command="$2"

# Check if the alias already exists
if gh alias list | grep -q "^$alias_name "; then
    echo "Alias '$alias_name' already exists. Please choose a different name."
    exit 1
fi

# Create the alias
gh alias set "$alias_name" "$command"

if [ $? -eq 0 ]; then
    echo "Alias '$alias_name' created successfully for command: $command"
else
    echo "Failed to create alias '$alias_name'."
    exit 1
fi