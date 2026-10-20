#!/bin/bash

# AWS Connection Script
# This script helps you set up and connect to AWS from the command line

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if AWS CLI is installed
check_aws_cli() {
    print_header "Checking AWS CLI Installation"
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed"
        echo "To install AWS CLI v2, run:"
        echo ""
        echo "# On Linux/Mac:"
        echo "curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'"
        echo "unzip awscliv2.zip"
        echo "sudo ./aws/install"
        echo ""
        echo "# On macOS with Homebrew:"
        echo "brew install awscli"
        echo ""
        return 1
    fi
    
    AWS_VERSION=$(aws --version)
    print_success "AWS CLI is installed: $AWS_VERSION"
    return 0
}

# Check if credentials are configured
check_credentials() {
    print_header "Checking AWS Credentials"
    
    if [ -f ~/.aws/credentials ]; then
        print_success "AWS credentials file exists"
        
        # Count profiles
        PROFILE_COUNT=$(grep -c '^\[' ~/.aws/credentials || echo 0)
        echo "Found $PROFILE_COUNT profile(s)"
        
        grep '^\[' ~/.aws/credentials | sed 's/\[//g' | sed 's/\]//g'
        return 0
    else
        print_warning "No AWS credentials file found at ~/.aws/credentials"
        return 1
    fi
}

# Configure new credentials
configure_credentials() {
    print_header "Configuring AWS Credentials"
    
    echo "You can configure credentials in two ways:"
    echo ""
    echo "1) Interactive setup (recommended for beginners)"
    echo "2) Manual entry"
    echo ""
    read -p "Choose option (1 or 2): " setup_option
    
    if [ "$setup_option" = "1" ]; then
        aws configure
    else
        read -p "Enter AWS Access Key ID: " access_key
        read -sp "Enter AWS Secret Access Key: " secret_key
        echo ""
        read -p "Enter default region (e.g., us-east-1): " region
        read -p "Enter default output format (json/table/text, default: json): " output_format
        
        mkdir -p ~/.aws
        
        cat >> ~/.aws/credentials << EOF
[default]
aws_access_key_id = $access_key
aws_secret_access_key = $secret_key
EOF
        
        cat >> ~/.aws/config << EOF
[default]
region = $region
output = ${output_format:-json}
EOF
        
        print_success "Credentials configured"
    fi
}

# Test AWS connection
test_connection() {
    print_header "Testing AWS Connection"
    
    # Get current identity
    if IDENTITY=$(aws sts get-caller-identity 2>&1); then
        print_success "Successfully connected to AWS!"
        echo ""
        echo "Account details:"
        echo "$IDENTITY" | grep -E "Account|UserId|Arn"
    else
        print_error "Failed to connect to AWS"
        echo "Error: $IDENTITY"
        return 1
    fi
}

# List available AWS profiles
list_profiles() {
    print_header "Available AWS Profiles"
    
    if [ -f ~/.aws/credentials ]; then
        grep '^\[' ~/.aws/credentials | sed 's/\[//g' | sed 's/\]//g'
    else
        print_error "No credentials file found"
        return 1
    fi
}

# Switch AWS profile
switch_profile() {
    print_header "Switch AWS Profile"
    
    list_profiles
    echo ""
    read -p "Enter profile name to switch to: " profile_name
    
    export AWS_PROFILE=$profile_name
    print_success "Switched to profile: $AWS_PROFILE"
    
    # Test the new profile
    if aws sts get-caller-identity &> /dev/null; then
        print_success "Profile is valid and working"
    else
        print_error "Profile is not working or credentials are invalid"
        return 1
    fi
}

# Main menu
show_menu() {
    echo ""
    echo "AWS Connection Script"
    echo "====================="
    echo ""
    echo "1) Check AWS CLI installation"
    echo "2) Check credentials"
    echo "3) Configure credentials"
    echo "4) Test connection"
    echo "5) List profiles"
    echo "6) Switch profile"
    echo "7) Full setup (check CLI + check/configure creds + test)"
    echo "8) Exit"
    echo ""
    read -p "Choose an option (1-8): " choice
}

# Main script
main() {
    while true; do
        show_menu
        
        case $choice in
            1) check_aws_cli ;;
            2) check_credentials ;;
            3) configure_credentials ;;
            4) test_connection ;;
            5) list_profiles ;;
            6) switch_profile ;;
            7)
                check_aws_cli && check_credentials || configure_credentials
                test_connection
                ;;
            8)
                print_success "Exiting"
                exit 0
                ;;
            *)
                print_error "Invalid option"
                ;;
        esac
    done
}

# Run main function
main
