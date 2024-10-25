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

# Read input and exclusion lists into arrays, skipping blank lines
input_list=()
while IFS= read -r line; do
    # Only add non-blank lines
    if [[ -n "$line" ]]; then
        input_list+=("$line")
    fi
done < "$input_file"

exclusion_list=()
while IFS= read -r line; do
    exclusion_list+=("$line")
done < "$exclusion_file"

# Function to check if a line contains any exclusion substring
is_excluded() {
    local line="$1"
    for exclude in "${exclusion_list[@]}"; do
        # Check if the line contains the exclusion substring
        if [[ "$line" == *"$exclude"* ]]; then
            return 0  # Line is excluded
        fi
    done
    return 1  # Line is not excluded
}

# Traverse the directory for all *.exc files
find "$directory" -type f -name "*.exc" | while IFS= read -r exc_file; do
    echo "Processing: $exc_file"
   
    # Create a temporary file for storing updated content
    tmp_file=$(mktemp /tmp/tempfile.XXXXXX) || { echo "Failed to create temp file"; exit 1; }

    # Read the .exc file line by line
    while IFS= read -r line; do
        # Trim leading and trailing spaces from the line for comparison
        trimmed_line=$(echo "$line" | xargs)
        should_delete=false

        for input in "${input_list[@]}"; do
            # Check if the line contains the input substring, skipping empty lines
            if [[ "$trimmed_line" == *"$input"* ]]; then
                # Check if the line contains any exclusion substring
                if is_excluded "$trimmed_line"; then
                    echo "Skipping excluded line: $trimmed_line"
                else
                    echo "Deleting line: $trimmed_line"
                    should_delete=true
                    # Log the deletion
                    echo "$(date): Deleted line '$trimmed_line' from file $exc_file" >> "$log_file"
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
