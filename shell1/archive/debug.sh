#!/bin/bash

# Configuration variables
CONFIG_DIR="/home/senthil/shell"         # Path to the directory containing YAML files
INPUT_FILE="input.txt"      # Path to the input file containing user list
EXCLUDE_FILE="exclusion.txt"  # Path to the exclusion file
TRACELOG="tracelog.log"     # Path to the trace log file
DELETED_LOG="deleted.log"   # Path to the deleted users log file

# Create or clear the log files
> "$TRACELOG"
> "$DELETED_LOG"

# Read exclusion list into an array for faster comparison
mapfile -t EXCLUDE_USERS < "$EXCLUDE_FILE"

# Function to check if a user is in the exclusion list
is_excluded() {
    local user="$1"
    for excluded_user in "${EXCLUDE_USERS[@]}"; do
        if [[ "${excluded_user,,}" == "${user,,}" ]]; then
            return 0  # User is excluded
        fi
    done
    return 1  # User is not excluded
}

# Read the user list from the input file
while IFS= read -r user; do
    # Log activity
    echo "Processing user: $user" | tee -a "$TRACELOG"

    # Check if the user is excluded
    if is_excluded "$user"; then
        echo "User $user is excluded from deletion." | tee -a "$TRACELOG"
        continue
    fi

    # Find and delete the user in YAML files (case insensitive)
    found=false
    while IFS= read -r -d '' yaml_file; do
        if grep -iq "$user" "$yaml_file"; then
            found=true
            # Remove the line containing the user from the YAML file
            sed -i.bak "/$user/Id" "$yaml_file"  # Delete line, create a backup
            echo "Deleted user $user from $yaml_file" | tee -a "$DELETED_LOG"
            echo "Deleted line from $yaml_file" | tee -a "$TRACELOG"
        fi
    done < <(find "$CONFIG_DIR" -name '*.exc' -print0)

    if ! $found; then
        echo "User $user not found in any YAML files." | tee -a "$TRACELOG"
    fi

done < "$INPUT_FILE"

echo "User deletion process completed." | tee -a "$TRACELOG"
