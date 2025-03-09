#!/bin/bash
set -e # Exit if any command fails

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Check if login is required
if ! docker info | grep -q 'Username:'; then

    echo "You are not logged in"
   
    read -p "Enter DockerHub Username: " username
    read -s -p "Enter DockerHub Password: " password
    echo

    # Secure login
    echo "$password" | docker login -u "$username" --password-stdin

    unset password
fi


echo "✅ You are logged in to Docker Hub."