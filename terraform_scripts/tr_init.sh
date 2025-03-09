#!/bin/bash
set -e 

# Check if terraform is installed
if ! [ -x "$(command -v terraform)" ]; then
    echo "Terraform is not installed. Please install Terraform."
    exit 1
fi

echo "✅ Terraform is installed successfully !"