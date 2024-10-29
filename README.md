Bash script designed for automating user management tasks, specifically targeting users with domain name and email addresses in YAML configuration files. Here's a detailed flow of the script:

1. Variable Initialization
Sets up various configuration variables such as paths to directories, files, JIRA API token, and JIRA project details.
2. Create JIRA Payload
Constructs a JSON payload using jq to create a new JIRA ticket for tracking inactive user deletions.
3. Load JIRA API Token
Reads the JIRA API token from a secure file for authentication.
4. Git Operations
Navigates to the specified Git repository and pulls the latest changes from the senthil branch.
5. Capture Yahoo Users
Searches through all YAML files in the configuration directory for email addresses ending with @example.com and stores them in a temporary file.
6. Remove Duplicates
Sorts the temporary file to remove duplicate entries and saves the unique users to current.out.
7. Identify Inactive Users
Compares the captured Yahoo users with a list of active users to identify inactive ones and stores them in inactive_users.txt.
8. Filter Excluded Users
Filters out any users listed in the exclusion file, ensuring that users meant to be retained are not flagged for deletion.
9. Check for Inactive Users
Checks if the inactive_users.txt file is empty. If it is, the script logs this and exits.
10. Create JIRA Ticket
Sends a POST request to create a JIRA ticket for the identified inactive users using the previously constructed payload. Logs the result.
11. Upload Inactive Users List
Uploads the inactive_users.txt file as an attachment to the created JIRA ticket.
12. Git Branching
Creates a new Git branch named after the JIRA ticket for further modifications related to the user deletions.
13. Delete Inactive Users
Iterates over the inactive users and deletes their entries from all YAML files in the configuration directory, logging each deletion.
14. Commit and Push Changes
Stages the changes, commits them with a message that includes the JIRA ticket number, and pushes the branch to the remote repository.
15. Upload Deleted Users Log
Finally, uploads a log of deleted users to the JIRA ticket for reference.
16. Completion Log
Outputs a completion message indicating that the user deletion automation process has finished.

Outcome:
This script effectively automates the process of identifying and deleting inactive domain users from YAML configuration files, tracking the changes via Git, and integrating with JIRA for issue management. Each step is logged for auditing purposes, ensuring transparency and traceability throughout the process.
