#!/bin/bash

# Variables
CONFIG_DIR="/home/senthil/shell/myuser"
CURRENT_FILE="current.out"
ACTIVE_USERS_FILE="active_users.txt"
INACTIVE_USERS_FILE="inactive-users.out"
EXCLUSION_FILE="exclusion.excl"
TRACE_LOG="tracelog.log"
DELETED_LOG="deleted_users.log"
DATE=$(date +"%Y-%m-%d")

# Step 1: Capture @yahoo.com users from YAML files
echo "Capturing users ending with @yahoo.com..." | tee -a "$TRACE_LOG"
find "$CONFIG_DIR" -name "*.yaml" -type f | while read yaml_file; do
  grep -ioP '\S+@yahoo\.com' "$yaml_file" >> temp_users.out
done

# Step 2: Remove duplicate users
echo "Removing duplicate usernames..." | tee -a "$TRACE_LOG"
sort -u temp_users.out > "$CURRENT_FILE"
rm temp_users.out

# Step 3: Compare current users with active users
echo "Comparing with active user list..." | tee -a "$TRACE_LOG"
grep -Fvxi -f "$ACTIVE_USERS_FILE" "$CURRENT_FILE" > "$INACTIVE_USERS_FILE"

# Step 4: Filter inactive users from exclusion list
echo "Filtering inactive users from the exclusion list..." | tee -a "$TRACE_LOG"
grep -Fvxi -f "$EXCLUSION_FILE" "$INACTIVE_USERS_FILE" > filtered_inactive_users.out
mv filtered_inactive_users.out "$INACTIVE_USERS_FILE"

# Step 5: Delete inactive users from YAML files
echo "Deleting inactive users from YAML files..." | tee -a "$TRACE_LOG"
while read user; do
  find "$CONFIG_DIR" -name "*.yaml" -type f | while read yaml_file; do
    if grep -iq "$user" "$yaml_file"; then
      echo "$DATE Deleting $user from $yaml_file" | tee -a "$TRACE_LOG" "$DELETED_LOG"
      sed -i "/$user/d" "$yaml_file"
    fi
  done
done < "$INACTIVE_USERS_FILE"

# Step 6: Cleanup
echo "Cleaning up temporary files..." | tee -a "$TRACE_LOG"
rm "$INACTIVE_USERS_FILE"

echo "User deletion process completed." | tee -a "$TRACE_LOG"
