#!/bin/bash

# Define variables
CONFIG_DIR="/home/senthil/repo/Automation/myuser"
CURRENT_FILE="current.out"
ACTIVE_USER_FILE="active_users.txt"
INACTIVE_USER_FILE="inactive-users.txt"
EXCLUSION_FILE="exclusion.excl"
TRACE_LOG="tracelog.log"
DELETE_LOG="deleted_users.log"
GIT_REPO_PATH="/home/senthil/repo/Automation"
# Jira Variables
JIRA_API_URL="https://lapog17.atlassian.net/rest/api/2/issue"
JIRA_PROJECT_KEY="SEN"
JIRA_API_TOKEN="ATATT3xFfGF0IZZKbb_DFIckukbfEaUCUOy0CT-JhMln3etrx6wEP06v9YIYq2BX1ZqhklYOTjMdPa_2vJlSo27iQTtOd7_Zx0kR822auuu-kuk09Pi74uoFQI1SismZKwXhuCVz3X8k_Bi_t93HF6a13VYkFUM4XN_dnNGJAkG1v7Gt5vlm8Uo=235B8F8A"



# Step 1: Scan YAML files for @yahoo.com emails and create `current.out` file
echo "Scanning YAML files for @yahoo.com users..." | tee -a "$TRACE_LOG"
grep -rhPo '[\w\.-]+@yahoo\.com' "$CONFIG_DIR"/*.yaml | sort -u | sed 's/@yahoo\.com//' > "$CURRENT_FILE"

# Step 2: Compare current.out with active-users list to get inactive users
echo "Identifying inactive users..." | tee -a "$TRACE_LOG"
grep -Fxiv -f "$ACTIVE_USER_FILE" "$CURRENT_FILE" | grep -Fxiv -f "$EXCLUSION_FILE" > "$INACTIVE_USER_FILE"

# Check if there are inactive users
if [ ! -s "$INACTIVE_USER_FILE" ]; then
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
curl -s -X POST -H "Authorization: Bearer $JIRA_API_TOKEN" -H "X-Atlassian-Token: no-check" -F "file=@$INACTIVE_USER_FILE" "$JIRA_API_URL/$TICKET_NUMBER/attachments"


# Step 4: Create Git branch named after JIRA ticket number
echo "Creating Git branch $TICKET_NUMBER..." | tee -a "$TRACE_LOG"
cd "$GIT_REPO_PATH"
git checkout -b "$TICKET_NUMBER"

# Step 5: Delete inactive users from YAML files
echo "Deleting inactive users from YAML files..." | tee -a "$TRACE_LOG"
while IFS= read -r user; do
    grep -rl "$user@yahoo.com" "$CONFIG_DIR"/*.yaml | xargs sed -i "/$user@yahoo.com/d"
    echo "Deleted $user@yahoo.com" | tee -a "$DELETE_LOG"
done < "$INACTIVE_USER_FILE"

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
