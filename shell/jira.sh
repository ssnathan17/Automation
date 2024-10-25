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

# Construct the JSON payload
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

# Make the API call to create the JIRA ticket
RESPONSE=$(curl -s -u "$JIRA_USER:$JIRA_API_TOKEN" \
  -X POST \
  --data "$JSON_PAYLOAD" \
  -H "Content-Type: application/json" \
  "$JIRA_BASE_URL/rest/api/2/issue/")

# Display the response
echo "JIRA Response: $RESPONSE"
