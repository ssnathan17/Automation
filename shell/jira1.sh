#!/bin/bash

# JIRA Credentials and URL
JIRA_USER="lapog17@yahoo.com"
JIRA_API_TOKEN="ATATT3xFfGF0wzxsGDZCopK13g-nuZmuEvCw7OkYYvSMVkFzctFB9Zvzv_ha2h0vtgjet3U4_jK6CJvi5BvTmzq9PVgpfPk-sp7yZ5SLMyRoGR1vZASWKo1huP78bwX8zqnXDoevyJCJDbeVl8lcL2ceLerwT7swfQKezNL1bzVspho0TQJiPqQ=1747A699"
JIRA_BASE_URL="https://lapog17.atlassian.net"
JIRA_PROJECT_KEY="SEN"  # Replace with your project key
JIRA_ISSUE_TYPE="Task"   # Replace with your issue type

# Ticket Information (can be taken as input or hardcoded)
SUMMARY="Automation Ticket to delete the in-active users"
DESCRIPTION="Delte the listed users from the account"

LOG_FILE="current.out"


# Construct the JSON payload for the ticket creation
JSON_PAYLOAD=$(cat <<EOF
{
  "fields": {
    "project": {
      "key": "$JIRA_PROJECT_KEY"
    },
    "summary": "$SUMMARY",
    "description": "$DESCRIPTION",
    "issuetype": {
      "name": "$JIRA_ISSUE_TYPE"
    }
  }
}
EOF
)

# Step 1: Create the JIRA Ticket
RESPONSE=$(curl -s -u "$JIRA_USER:$JIRA_API_TOKEN" \
  -X POST \
  --data "$JSON_PAYLOAD" \
  -H "Content-Type: application/json" \
  "$JIRA_BASE_URL/rest/api/2/issue/")

# Extract the JIRA Ticket ID from the response
TICKET_ID=$(echo $RESPONSE | jq -r '.key')

# Check if ticket creation was successful
if [ "$TICKET_ID" == "null" ] || [ -z "$TICKET_ID" ]; then
  echo "Failed to create JIRA ticket. Response: $RESPONSE"
  exit 1
fi

echo "JIRA Ticket $TICKET_ID created successfully."

# Step 2: Attach the log file to the created JIRA ticket
ATTACH_RESPONSE=$(curl -s -u "$JIRA_USER:$JIRA_API_TOKEN" \
  -X POST \
  -H "X-Atlassian-Token: no-check" \
  -F "file=@$LOG_FILE" \
  "$JIRA_BASE_URL/rest/api/2/issue/$TICKET_ID/attachments")

# Check if the file attachment was successful
if echo "$ATTACH_RESPONSE" | grep -q "\"filename\":\"$LOG_FILE\""; then
  echo "File $LOG_FILE successfully attached to ticket $TICKET_ID."
else
  echo "Failed to attach file. Response: $ATTACH_RESPONSE"
  exit 1
fi
