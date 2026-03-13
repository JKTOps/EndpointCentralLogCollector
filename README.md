# macOS Managed Log Collector & Azure Uploader

## Overview
This script is a lightweight, automated solution for collecting diagnostic logs from **ManageEngine (MEMDM)** and **UEMS Agents** on macOS devices. It archives the logs and securely uploads them to an **Azure Blob Storage** container via the REST API, ensuring zero interaction is required from the end user.

## Features
* **Silent Execution:** Runs entirely in the background using `/private/tmp`.
* **Invisible to User:** No UI prompts, disk mounting, or Downloads folder clutter.
* **Cloud Integration:** Uploads directly to Azure over HTTPS (Port 443)—no VPN or network share required.
* **Security Focused:** Uses a **Write-Only SAS Token** to prevent unauthorized data access.
* **Automatic Cleanup:** Removes temporary local archives immediately after a successful upload.

## Technical Workflow
1.  **Privilege Verification:** The script checks for `root` privileges to ensure it can read protected system logs in `/Library/`.
2.  **Archiving:** It uses the native `/usr/bin/zip` utility to compress:
    * `/Library/MEMDM_agent/logs`
    * `/Library/ManageEngine/UEMS_Agent/logs`
3.  **Naming Convention:** Generates a unique filename using the machine's local hostname and a timestamp: 
    * `[Hostname]_Logs_[YYYYMMDD_HHMMSS].zip`
4.  **API Upload:** Uses `curl` to perform a `PUT` request to Azure Blob Storage. 
5.  **Status Check:** Verifies the HTTP response code. If the server returns `201 Created`, the local file is deleted.

## Configuration
The following variables must be defined within the script before deployment:
* `AZURE_BASE_URL`: The URL to your specific Azure Blob container.
* `SAS_TOKEN`: A Shared Access Signature token with **Add** and **Create** permissions.

## Deployment via UEMS / MDM
To deploy this script through a management console:
1.  **Run As:** System / Root.
2.  **Frequency:** Can be run on-demand for troubleshooting or as a scheduled maintenance task.
3.  **Arguments:** No arguments are required for basic log collection.

## Security Considerations
* **SAS Permissions:** It is highly recommended to use a **Write-Only** SAS token. This ensures that even if the token is compromised, it cannot be used to list or download logs from other machines.
* **Encryption:** All data is encrypted in transit via TLS (HTTPS).

---
*Should Be Maintained by IT*
