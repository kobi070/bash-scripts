#!/bin/bash
echo "Checking if Minikube exists in your machine..."

# Check if docker is installed
# You got to have docker installed to run this version of minikube
if ! [ docker ]; then
    echo 'Error: docker is not installed.' >&2
    exit 1
fi

Checks if minikube is already installed in your machine
if [ minikube ]; then
    echo "Minikube already exist in your machine"
    exit 1
else
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
    sudo dpkg -i minikube_latest_amd64.deb

    read -p "Would you like to alias ['minikube kubectl --'] ? [Y/N] " useranswer

    if [ "$useranswer" == "Y" ]; then
        alias kubectl="minikube kubectl --"
    else
        exit 1
    fi

fi
