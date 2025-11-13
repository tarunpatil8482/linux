#!/bin/bash

# Usage: sudo ./create_users.sh users.txt

FILE=$1

# Must run as root
if [ "$EUID" -ne 0 ]; then
    echo "❗ Please run with sudo"
    exit 1
fi

# Check file
if [ ! -f "$FILE" ]; then
    echo "❗ File not found: $FILE"
    exit 1
fi

# Secure folders
mkdir -p /var/secure
chmod 700 /var/secure

PASSWORD_FILE="/var/secure/user_passwords.txt"
LOG_FILE="/var/log/user_management.log"

touch "$PASSWORD_FILE"
chmod 600 "$PASSWORD_FILE"

touch "$LOG_FILE"
chmod 600 "$LOG_FILE"

echo "Starting user creation process..." | tee -a "$LOG_FILE"

# Read each line
while read line; do

    # Trim whitespace
    line=$(echo "$line" | xargs)

    # Skip empty lines
    [ -z "$line" ] && continue

    # Skip comment lines (#...)
    if [[ $line == \#* ]]; then
        echo "Skipping comment line" >> "$LOG_FILE"
        continue
    fi

    # Extract username and groups
    username=$(echo "$line" | cut -d ";" -f1 | tr -d " ")
    groups=$(echo "$line"    | cut -d ";" -f2 | tr -d " ")

    echo "Processing user: $username" | tee -a "$LOG_FILE"

    # Create user if not exists
    if id "$username" &>/dev/null; then
        echo "User '$username' already exists" >> "$LOG_FILE"
    else
        useradd -m "$username"
        echo "Created user $username" >> "$LOG_FILE"
    fi

    # Ensure home directory exists
    if [ ! -d "/home/$username" ]; then
        mkdir -p "/home/$username"
        echo "Created home directory for $username" >> "$LOG_FILE"
    fi

    # Fix permissions
    chown -R "$username:$username" "/home/$username"

    # Add extra groups
    if [ -n "$groups" ]; then
        IFS=',' read -ra g <<< "$groups"
        for group in "${g[@]}"; do

            # Create group if missing
            if ! getent group "$group" >/dev/null; then
                groupadd "$group"
                echo "Created group $group" >> "$LOG_FILE"
            fi

            usermod -aG "$group" "$username"
            echo "Added $username to group $group" >> "$LOG_FILE"
        done
    fi

    # Create random 12-character password
    password=$(openssl rand -base64 9)

    # Set password
    echo "$username:$password" | chpasswd

    # Save password securely
    echo "$username : $password" >> "$PASSWORD_FILE"

done < "$FILE"

echo "Done! ✔ All actions logged in $LOG_FILE"
echo "Passwords saved in $PASSWORD_FILE"

