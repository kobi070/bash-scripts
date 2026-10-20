#!/bin/bash
set -e

# Parse argument
while [[ "$#" -gt 0 ]]; do
    case $1 in
    -arg)
        userapp="$2"
        shift
        ;;
    *)
        echo "Unknown parameter passed: $1"
        exit 1
        ;;
    esac
    shift
done

# Check if userapp is provided
if [[ -z "$userapp" ]]; then
    echo "Usage: $0 -arg AppName"
    exit 1
fi

# Check if the command exists
if ! command -v "$userapp" >/dev/null 2>&1; then
    echo "❌ App '$userapp' does not exist on your machine. Please install it."
    exit 1
fi

# Try to enable autocompletion
completion_output="$($userapp completion bash 2>/dev/null || true)"
if [[ -n "$completion_output" ]]; then
    completion_cmd="source <($userapp completion bash)"
# Fall back to a '<app>_completer' binary (e.g. AWS CLI v2's aws_completer)
elif command -v "${userapp}_completer" >/dev/null 2>&1; then
    completion_cmd="complete -C '$(command -v "${userapp}_completer")' $userapp"
else
    echo "⚠️  No bash completion available from '$userapp'."
    exit 1
fi

# Add to ~/.bashrc
echo "Enabling autocomplete for '$userapp'..."
if ! grep -q "$completion_cmd" ~/.bashrc; then
    echo "$completion_cmd" >>~/.bashrc
    echo "✅ Added to ~/.bashrc"
else
    echo "✅ Already enabled in ~/.bashrc"
fi

# Reload bashrc for current session (optional)
echo "To apply changes now, run: source ~/.bashrc"
