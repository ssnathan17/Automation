#!/bin/bash

JIRA_API_TOKEN=$(< /home/senthil/security/.jira_credentials)
 

# Define variables
CONFIG_DIR="/home/senthil/repo/Automation/myuser"
CURRENT_FILE="current.out"
ACTIVE_USERS_FILE="active_users.txt"
INACTIVE_USERS_FILE="inactive-users.txt"
EXCLUSION_FILE="exclusion.excl"
TRACE_LOG="tracelog.log"
DELETE_LOG="deleted_users.log"
GIT_REPO_PATH="/home/senthil/repo/Automation"
# Jira Variables
JIRA_API_URL="https://lapog17.atlassian.net/rest/api/2/issue"
JIRA_PROJECT_KEY="SEN"

if [ -z "$JIRA_API_TOKEN" ]; then
  echo "JIRA API token not found. Please ensure /home/senthil/security/.jira_credentials file exists and contains the token."
  exit 1
fi

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

# Check if there are inactive users
if [ ! -s "$INACTIVE_USERS_FILE" ]; then
    echo "No inactive users found." | tee -a "$TRACE_LOG"
    exit 0
fi

# Step 3: Create JIRA ticket
echo "Creating JIRA ticket for inactive user deletion..." | tee -a "$TRACE_LOG"
TICKET_RESPONSE=$(curl -s -X POST -H "Authorization: Bearer $JIRA_API_TOKEN" -H "Content-Type: application/json" \
    -d "{\"fields\":{\"project\":{\"key\":\"$JIRA_PROJECT_KEY\"},\"summary\":\"Inactive user deletion automation\",\"description\":\"Automated ticket for deleting inactive users\",\"issuetype\":{\"name\":\"Task\"}}}" "$JIRA_API_URL")
TICKET_NUMBER=$(echo "$TICKET_RESPONSE" | jq -r '.key')

# Upload inactive user file to JIRA ticket
echo "Uploading inactive user list to JIRA ticket..." | tee -a "$TRACE_LOG"
curl -s -X POST -H "Authorization: Bearer $JIRA_API_TOKEN" -H "X-Atlassian-Token: no-check" -F "file=@$INACTIVE_USERS_FILE" "$JIRA_API_URL/$TICKET_NUMBER/attachments"


# Step 4: Create Git branch named after JIRA ticket number
echo "Creating Git branch $TICKET_NUMBER..." | tee -a "$TRACE_LOG"
cd "$GIT_REPO_PATH"
git checkout -b "$TICKET_NUMBER"

# Step 5: Delete inactive users from YAML files
echo "Deleting inactive users from YAML files..." | tee -a "$TRACE_LOG"
while IFS= read -r user; do
    grep -rl "$user@yahoo.com" "$CONFIG_DIR"/*.yaml | xargs sed -i "/$user@yahoo.com/d"
    echo "Deleted $user@yahoo.com" | tee -a "$DELETE_LOG"
done < "$INACTIVE_USERS_FILE"

# Step 6: Commit and push changes to Git
echo "Committing and pushing changes to Git..." | tee -a "$TRACE_LOG"
git add .
git commit -m "$TICKET_NUMBER: Inactive user deletion automation"
git push origin "$TICKET_NUMBER"

# Upload deletion log to JIRA ticket
echo "Uploading deletion log to JIRA ticket..." | tee -a "$TRACE_LOG"
echo "Uploading deletion log to JIRA ticket..." | tee -a "$TRACE_LOG"
curl -s -X POST -H "Authorization: Bearer $JIRA_API_TOKEN" -H "X-Atlassian-Token: no-check" -F "file=@$DELETE_LOG" "$JIRA_API_URL/$TICKET_NUMBER/attachments"

echo "User deletion automation script completed successfully." | tee -a "$TRACE_LOG"
