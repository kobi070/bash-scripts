#!/bin/bash
set -e

function diskUsage() {
    df -h
}

function cpuInfo() {
    lscpu
}

function hardwareInfo() {
    sudo lshw
}

function memoryInfo() {
    free -h
}

function systemInfo() {
    uname -a
}

echo "Welcome to Sys Info Menu"
echo "1. Check Disk Usage"
echo "2. Check CPU Info"
echo "3. Check Hardware Info"
echo "4. Memory Info"
echo "5. Check System Info"
echo "6. Exit"
read -p "Please enter a number between [1-6]: " useraction

# If the user choice was 6 then we exit the script
if [ "$useraction" == "6" ]; then
    echo "Exiting"
    exit 1
fi

# If the user choice was 1-5 we will perform different set of functions
if [ "$useraction" == "1" ]; then
    echo "Checking disk usage..."
    diskUsage
elif [ "$useraction" == "2" ]; then
    echo "Checking CPU information..."
    cpuInfo
elif [ "$useraction" == "3" ]; then
    echo "Checking HW information..."
    hardwareInfo
elif [ "$useraction" == "4" ]; then
    echo "Checking memory information..."
    memoryInfo
elif [ "$useraction" == "5" ]; then
    echo "Checking system information..."
    systemInfo
else
    echo "Invalid option. Please enter a number between 1 and 6."
fi
