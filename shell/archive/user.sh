#!/bin/bash

# Define the variables here
input_file="input.txt"         # Path to the input file with lines to delete
exclusion_file="exclusion.txt" # Path to the exclusion file
directory="/home/senthil/shell" # Directory to search for .exc files
log_file="deletion_log.txt"    # Path to the log file

# Check if input and exclusion files exist
if [ ! -f "$input_file" ] || [ ! -f "$exclusion_file" ]; then
    echo "Input or exclusion file does not exist."
    exit 1
fi

# Create or clear the log file
echo "Deletion log - $(date)" > "$log_file"

# Read input and exclusion lists into arrays
mapfile -t input_list < "$input_file"
mapfile -t exclusion_list < "$exclusion_file"

# Function to check if a line is in the exclusion list
is_excluded() {
    local line="$1"
    for exclude in "${exclusion_list[@]}"; do
        if [[ "$line" =~ "$exclude" ]]; then
            return 0  # Line is excluded
        fi
    done
    return 1  # Line is not excluded
}

# Traverse the directory for all *.exc files
find "$directory" -type f -name "*.exc" | while IFS= read -r exc_file; do
    echo "Processing: $exc_file"    >> "$log_file"
   
    # Create a temporary file for storing updated content
    tmp_file=$(mktemp)

    # Read the .exc file line by line
    while IFS= read -r line; do
        # Check if the line is in the input list
        should_delete=false
        for input in "${input_list[@]}"; do
            if [[ "$line" =~ "$input" ]]; then
                if is_excluded "$line"; then
                    echo "Skipping excluded line: $line"   >> "$log_file"
                else
                    echo "Deleting line: $line"   >> "$log_file"
                    should_delete=true
                    # Log the deletion
                    echo "$(date): Deleted line '$line' from file $exc_file" >> "$log_file"
                fi
                break
            fi
        done

        # If the line is not to be deleted, add it to the temp file
        if [ "$should_delete" = false ]; then
            echo "$line" >> "$tmp_file"
        fi
    done < "$exc_file"

    # Move the temporary file back to the original .exc file
    mv "$tmp_file" "$exc_file"
done

echo "Processing complete. Deletions logged in $log_file."
