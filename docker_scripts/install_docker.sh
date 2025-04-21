#!/bin/bash
set -e

## This instruction from the official website will install the latest release of docker.

# Uninstall old versions
# Older versions of Docker were called docker, docker.io, or docker-engine. If these are installed, uninstall them:
sudo apt remove docker docker-engine docker.io containerd runc

# Install using the repository 
sudo apt update
sudo apt-get install ca-certificates curl gnupg lsb-release
      
# Add Docker’s official GPG key:
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository     
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Receiving a GPG error when running apt-get update?
# Your default umask may not be set correctly, causing the public key file for the repo to not be detected. Run the following command and then try to update your repo again: sudo chmod a+r /etc/apt/keyrings/docker.gpg.

# Verify that Docker Engine is installed correctly by running the hello-world image
sudo docker run hello-world
#This command downloads a test image and runs it in a container. When the container runs, it prints a message and exits