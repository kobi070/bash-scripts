#!/bin/bash

# Welcome message
echo "Welcome to the process management menu!"

# List of processes to check
processes=("google-chrome" "firefox" "geany")

# The audit file
audit_file="process_audit_$(date '+%H%M').txt"

# Display the menu to the user
echo "Please choose an option:"
echo "1. Manage google-chrome"
echo "2. Manage firefox"
echo "3. Manage geany"
echo "4. Kill All Processes"

# Read user choice
read -p "Enter your choice (1-4): " user_choice

if [[ "$user_choice" -ge 1 && "$user_choice" -le 4 ]]; then
    if [ "$user_choice" -eq 4 ]; then
        # Option to kill all processes
        read -p "Are you sure you want to kill all processes? (y/n): " confirm_kill
        if [ "$confirm_kill" == "y" ]; then
            for process in "${processes[@]}"; do
                if pgrep "$process" > /dev/null; then
                    pkill "$process"
                    echo "$(date): Killed $process" >> "$audit_file"
                fi
            done
            echo "All specified processes have been killed."
        else
            echo "Kill all operation canceled."
        fi
    else
        # Managing a specific process
        process="${processes[$((user_choice - 1))]}"
        if pgrep "$process" > /dev/null; then
            # Process is running
            read -p "$process is running. Would you like to kill it? (y/n): " kill_choice
            if [ "$kill_choice" == "y" ]; then
                pkill "$process"
                echo "$(date): Killed $process" >> "$audit_file"
                echo "$process has been killed."
            else
                echo "$(date): User chose not to kill $process" >> "$audit_file"
            fi
        else
            # Process is not running
            read -p "$process is not running. Would you like to start it? (y/n): " start_choice
            if [ "$start_choice" == "y" ]; then
                $process&
                echo "$(date): Started $process" >> "$audit_file"
                echo "$process has been started."
            else
                echo "$(date): User chose not to start $process" >> "$audit_file"
            fi
        fi
    fi
else
    echo "Invalid choice. Please select a valid option (1-4)."
fi

echo "Process management complete. Audit log saved to $audit_file."
