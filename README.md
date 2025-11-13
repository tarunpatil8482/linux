User Creation Automation Script

This project helps you create many Linux users automatically.
You only need to write the users in a file called users.txt.
The script will read the file and create all users for you.

What the Script Does

The script will:

Create users written in users.txt

Create groups if they do not exist

Add the user to the groups listed

Create a home folder for each user

Make a random 12-character password for each user

Save all passwords in /var/secure/user_passwords.txt

Save all logs in /var/log/user_management.log

Skip empty lines and lines starting with #

How to Write users.txt

Here is an example users.txt file:

# This line is a comment. The script will skip it.

tarunpatil; dev,testing,www-data,devops
tarun; sudo,dev
rahul; www-data
bheema; intern


Format:

username; group1,group2,group3


Important:

Use ; to separate username and groups

Use , between groups

Lines starting with # will be ignored

How to Run the Script
Step 1: Give permission

Open the terminal in VS Code and run:

chmod +x create_users.sh

Step 2: Run the script (use sudo)
sudo ./create_users.sh users.txt

How to See the Passwords

Passwords are saved in this file:

/var/secure/user_passwords.txt


To view them:

sudo cat /var/secure/user_passwords.txt

How to See the Log File

The log file is here:

/var/log/user_management.log


To read it:

sudo cat /var/log/user_management.log

Security Notes

Only root can read the password file

Passwords are generated randomly

Passwords are not shown on the screen

Log file and password file have strict permissions

Requirements

Linux (Ubuntu recommended)

Must run with sudo

Bash shell

Why This Script Is Useful

Saves time

Prevents mistakes

Good for DevOps practice

Simple to use

Works for many users at once

Example Folder Structure
user-management/
├── create_users.sh
├── users.txt
└── README.md
