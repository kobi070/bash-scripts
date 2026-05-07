#!/bin/bash
set -euo pipefail

function diskUsage() {
    df -h
}

function cpuInfo() {
    if command -v lscpu >/dev/null 2>&1; then
        lscpu
    else
        echo "lscpu command not found."
    fi
}

function hardwareInfo() {
    if command -v lshw >/dev/null 2>&1; then
        sudo lshw
    else
        echo "lshw command not found. You might need to install it."
    fi
}

function memoryInfo() {
    free -h
}

function systemInfo() {
    uname -a
}

while true; do
    echo ""
    echo "--- Sys Info Menu ---"
    echo "1. Check Disk Usage"
    echo "2. Check CPU Info"
    echo "3. Check Hardware Info"
    echo "4. Memory Info"
    echo "5. Check System Info"
    echo "6. Exit"
    read -p "Please enter a number between [1-6]: " useraction

    case "$useraction" in
        1)
            echo "Checking disk usage..."
            diskUsage
            ;;
        2)
            echo "Checking CPU information..."
            cpuInfo
            ;;
        3)
            echo "Checking HW information..."
            hardwareInfo
            ;;
        4)
            echo "Checking memory information..."
            memoryInfo
            ;;
        5)
            echo "Checking system information..."
            systemInfo
            ;;
        6)
            echo "Exiting"
            break
            ;;
        *)
            echo "Invalid option. Please enter a number between 1 and 6."
            ;;
    esac
done
