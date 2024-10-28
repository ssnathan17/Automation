#!/bin/bash

# Configuration variables
CONFIG_DIR="/home/senthil/repo/Automation/myuser"             # Path to config directory containing YAML files
CURRENT_FILE="current.out"               # File to store current yahoo.com users
ACTIVE_USER_FILE="active_users.txt"      # Path to the active users report
INACTIVE_USER_FILE="inactive-users.txt"  # File to store inactive users
EXCLUSION_LIST="exclusion.excl"      # List of users to exclude from deletion
TRAC_LOG="tracelog.log"                  # Log file to trace all activities
DELETE_LOG="deleted-users.log"           # Log file to list deleted users
JIRA_API_TOKEN="/home/senthil/security/.jira_credentials" # Path to secure JIRA API token file
JIRA_PROJECT="SEN"         # JIRA project key or ID
GIT_REPO_PATH="/home/senthil/repo/Automation"
# Variables
JIRA_URL="https://lapog17.atlassian.net/rest/api/2/issue/"
USERNAME="lapog17@yahoo.com"  # Your Jira username
PROJECT_KEY="SEN"                   # Your Jira project key
SUMMARY="Automation"
DESCRIPTION="This is a sample description with logs:\n$LOG_CONTENT"
LOG_CONTENT="Log entry 1\nLog entry 2\nLog entry 3"  # Your log content goes here

# Create the JSON payload
PAYLOAD=$(jq -n --arg proj "$PROJECT_KEY" \
                --arg summary "$SUMMARY" \
                --arg description "$DESCRIPTION" \
                '{
                    fields: {
                        project: { key: $proj },
                        summary: $summary,
                        description: $description,
                        issuetype: { name: "Task" }  # Adjust issue type as necessary
                    }
                }')


# Load the JIRA API token securely
API_TOKEN=$(cat $JIRA_API_TOKEN)

echo "Pulling git repo" | tee -a "$TRACE_LOG"
cd "$GIT_REPO_PATH"
git pull


# Step 1: Capture @yahoo.com users from YAML files
echo "Capturing users ending with @yahoo.com..." | tee -a "$TRAC_LOG"
find "$CONFIG_DIR" -name "*.yaml" -type f | while read yaml_file; do
  grep -ioP '\S+@yahoo\.com' "$yaml_file" >> temp_users.out
done

# Step 2: Remove duplicate users
echo "Removing duplicate usernames..." | tee -a "$TRAC_LOG"
sort -u temp_users.out > "$CURRENT_FILE"
rm temp_users.out

# Step 3: Compare current users with active users
echo "Comparing with active user list..." | tee -a "$TRAC_LOG"
grep -Fvxi -f "$ACTIVE_USER_FILE" "$CURRENT_FILE" > "$INACTIVE_USER_FILE"

# Step 4: Filter inactive users from exclusion list
echo "Filtering inactive users from the exclusion list..." | tee -a "$TRAC_LOG"
grep -Fvxi -f "$EXCLUSION_LIST" "$INACTIVE_USER_FILE" > filtered_inactive_users.out
mv filtered_inactive_users.out "$INACTIVE_USER_FILE"

# Check if there are inactive users
if [ ! -s "$INACTIVE_USER_FILE" ]; then
    echo "No inactive users found." | tee -a "$TRAC_LOG"
    exit 0
fi
echo "Inactive users identified in $INACTIVE_USER_FILE" | tee -a $TRAC_LOG

# Step 3: Create JIRA ticket for inactive users
echo "Creating JIRA ticket..." | tee -a $TRAC_LOG
JIRA_RESPONSE=$(curl -s -u "$USERNAME:$API_TOKEN" -X POST \
  --data "$PAYLOAD" \
  -H "Content-Type: application/json" \
  "$JIRA_URL")

JIRA_TICKET=$(echo $JIRA_RESPONSE | jq -r '.key')
if [ "$JIRA_TICKET" == "null" ]; then
    echo "Failed to create JIRA ticket." | tee -a $TRAC_LOG
    exit 1
fi
echo "JIRA ticket created: $JIRA_TICKET" | tee -a $TRAC_LOG

# Upload inactive user file to JIRA ticket
echo "Uploading inactive user list to JIRA..." | tee -a $TRAC_LOG
curl -s  -u "$USERNAME:$API_TOKEN" -X POST \
    -F "file=@$INACTIVE_USER_FILE" \
    "https://lapog17.atlassian.net/rest/api/2/issue/$JIRA_TICKET/attachments"

# Step 4: Git operations
cd /home/senthil/repo/Automation || exit
BRANCH_NAME="$JIRA_TICKET"
git checkout -b "$BRANCH_NAME"
echo "Created new Git branch: $BRANCH_NAME" | tee -a $TRAC_LOG

# Step 5: Delete inactive users from YAML files
echo "Deleting inactive users from YAML files..." | tee -a $TRAC_LOG
while IFS= read -r user; do
    if ! grep -iqF "$user" "$EXCLUSION_LIST"; then
        find "$CONFIG_DIR" -type f -name "*.yaml" -exec sed -i "/$user@/Id" {} +
        echo "$user deleted from YAML files" | tee -a "$DELETE_LOG"
    fi
done < "$INACTIVE_USER_FILE"

# Step 6: Git commit and push changes
echo "Committing and pushing changes to Git..." | tee -a $TRAC_LOG
git add .
git commit -m "$JIRA_TICKET: In-active user deletion Automation"
git push origin "$BRANCH_NAME"
echo "Changes committed and pushed to branch $BRANCH_NAME" | tee -a $TRAC_LOG

# Upload deleted users log to JIRA ticket
echo "Uploading deleted user log to JIRA..." | tee -a $TRAC_LOG
curl -s -X POST -H "Authorization: Bearer $JIRA_TOKEN"  \
    -F "file=@$DELETE_LOG" \
    "https://lapog17.atlassian.net/rest/api/2/issue/$JIRA_TICKET/attachments"

echo "User deletion automation completed." | tee -a $TRAC_LOG
