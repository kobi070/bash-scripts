#!/bin/bash

# Usage: ./extract_cmake_project_name.sh path/to/CMakeLists.txt

CMAKE_FILE="$1"

if [[ ! -f "$CMAKE_FILE" ]]; then
  echo "Error: File '$CMAKE_FILE' not found."
  exit 1
fi

# Extract the project name from the first 'project(...)' line
PROJECT_NAME=$(grep -i '^\s*project\s*(' "$CMAKE_FILE" | head -n1 | \
  sed -E 's/^[^()]*\(\s*([^ )]+).*/\1/')

if [[ -z "$PROJECT_NAME" ]]; then
  echo "No project name found in $CMAKE_FILE"
  exit 2
fi

echo "$PROJECT_NAME"
