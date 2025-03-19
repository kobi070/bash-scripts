#!/bin/bash

# For loop to check if the process chrome, firefox, and geany
# if the process exists ask the user if they want to kill it => pkill <process_name>
# if the process does not exist ask the user to run it => 
# audit the user's choices. >> ($ts.audit.txt) 2> /dev/null 2>&1

date=$(date '+%H:%M')
echo "Welcome to the process exit menu"

# List of the processes to check
processes=("google-chrome" "firefox" "geany")

# The audit file
audit_file="$ts.audit.txt"

read -p "Would you like to kill all processes? [y/n]" killall
if [ "$killall" == "y" ] ;
	then 
		pkill chrome
		pkill firefox
		pkill geany
fi

for process in "${processes[@]}"; do
    # Check if the process is running
    if pgrep "$process" > /dev/null; then
        # If the process is running, ask the user if they want to kill it
        read -p "$process is running. Would you like to kill it? (y/n) " answer
        if [ "$answer" == "y" ]; then
            # Kill the process
            pkill "$process"
            echo "$(date): Killed $process" >> "$audit_file"
        else
            # User chose not to kill
            echo "$(date): User chose not to kill $process" >> "$audit_file"
        fi
    else
        # If the process is not running, ask the user to start it
        read -p "$process is not running. Please start it and confirm (y/n): " choice
        if [ "$choice" == "y" ]; then
            # User chose to start the process
            echo "$(date): User started $process" >> "$audit_file"
            $process&
            echo "$process started"
        else
            # User chose not to start the process
            echo "$(date): User did not start $process" >> "$audit_file"
        fi
    fi
done