#!/bin/bash

# Usage: ./extract_cmake_project_name.sh path/to/CMakeLists.txt

CMAKE_FILE="$1"

if [[ ! -f "$CMAKE_FILE" ]]; then
  echo "Error: File '$CMAKE_FILE' not found."
  exit 1
fi

# Extract the project name from the first 'project(...)' line
# Optimized: use a single sed command that quits after the first match to reduce process overhead and stop reading the file early.
PROJECT_NAME=$(sed -nE '/^\s*project\s*\(/I { s/^[^()]*\(\s*([^ )]+).*/\1/p; q }' "$CMAKE_FILE")

if [[ -z "$PROJECT_NAME" ]]; then
  echo "No project name found in $CMAKE_FILE"
  exit 2
fi

echo "$PROJECT_NAME"
