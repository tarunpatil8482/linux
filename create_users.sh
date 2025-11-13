#!/bin/bash

# Usage: sudo ./create_users.sh users.txt

INPUT_FILE="$1"

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo."
    exit 1
fi

# Check file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "File not found: $INPUT_FILE"
    exit 1
fi

# Secure storage locations
mkdir -p /var/secure
chmod 700 /var/secure

PASSWORD_FILE="/var/secure/user_passwords.txt"
LOG_FILE="/var/log/user_management.log"

touch "$PASSWORD_FILE"
chmod 600 "$PASSWORD_FILE"

touch "$LOG_FILE"
chmod 600 "$LOG_FILE"

echo "Starting user creation process..." | tee -a "$LOG_FILE"

# Convert CRLF (Windows) -> LF (Linux)
dos2unix "$INPUT_FILE" 2>/dev/null

# Process file line by line
while IFS= read -r line || [ -n "$line" ]; do

    # Trim spaces
    line=$(echo "$line" | xargs)

    # Skip empty lines
    [[ -z "$line" ]] && continue

    # Skip comments
    [[ $line == \#* ]] && {
        echo "Skipping comment: $line" >> "$LOG_FILE"
        continue
    }

    # Extract username and groups
    username=$(echo "$line" | cut -d ";" -f1 | tr -d " ")
    groups=$(echo "$line" | cut -d ";" -f2 | tr -d " ")

    echo "Processing user: $username" | tee -a "$LOG_FILE"

    # Create user if not already present
    if id "$username" &>/dev/null; then
        echo "User '$username' already exists" >> "$LOG_FILE"
    else
        useradd -m "$username"
        echo "Created user $username" >> "$LOG_FILE"
    fi

    # Make home directory if missing
    if [ ! -d "/home/$username" ]; then
        mkdir -p "/home/$username"
        echo "Created home directory for $username" >> "$LOG_FILE"
    fi

    # Assign correct permissions
    chown -R "$username:$username" "/home/$username"

    # Add user to listed groups
    if [ -n "$groups" ]; then
        IFS=',' read -ra list <<< "$groups"
        for group in "${list[@]}"; do

            # Create group if it doesn't exist
            if ! getent group "$group" > /dev/null; then
                groupadd "$group"
                echo "Created group: $group" >> "$LOG_FILE"
            fi

            usermod -aG "$group" "$username"
            echo "Added $username to group $group" >> "$LOG_FILE"
        done
    fi

    # Generate random password (12 characters)
    password=$(openssl rand -base64 9)

    # Apply the password
    echo "$username:$password" | chpasswd

    # Save password to secure file
    echo "$username : $password" >> "$PASSWORD_FILE"

done < "$INPUT_FILE"

echo "User creation complete! Log: $LOG_FILE"
echo "Passwords stored securely in: $PASSWORD_FILE"
