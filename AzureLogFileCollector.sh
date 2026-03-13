#!/bin/bash

# ==============================================================================
# Script Name:  collect_and_upload_logs.sh
# Description:  Zips specific MDM/UEMS (Endpoint Central) log paths and uploads to Azure Blob Storage.
# Author:       TienaOps (IT System Administrator)
# ==============================================================================

# --- CONFIGURATION (Pass these via MDM arguments or environment variables) ---
# DO NOT hardcode production SAS tokens here if the repo is public.

AZURE_BASE_URL="https://youraccount.blob.core.windows.net/container"
SAS_TOKEN="?sv=your_sas_token_here"

# --- SYSTEM VARIABLES ---
MACHINE_NAME=$(scutil --get LocalHostName)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ZIP_NAME="${MACHINE_NAME}_Logs_${TIMESTAMP}.zip"
TEMP_ZIP="/private/tmp/$ZIP_NAME"

LOG_PATH_1="/Library/MEMDM_agent/logs"
LOG_PATH_2="/Library/ManageEngine/UEMS_Agent/logs"

# --- 1. PRIVILEGE CHECK ---
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root (sudo) to access /Library/ paths."
  exit 1
fi

# --- 2. LOG COLLECTION ---
echo "Locating and zipping logs..."
# Using full path to zip and redirecting errors to /dev/null for a cleaner output
/usr/bin/zip -rq "$TEMP_ZIP" "$LOG_PATH_1" "$LOG_PATH_2"

if [ ! -f "$TEMP_ZIP" ]; then
    echo "Error: Could not create log archive. Verify if log directories exist."
    exit 1
fi

# --- 3. AZURE UPLOAD (HTTPS API) ---
echo "Uploading to Azure Storage..."
UPLOAD_URL="${AZURE_BASE_URL}/${ZIP_NAME}${SAS_TOKEN}"

# -s (silent), -S (show errors), -w (write out HTTP code)
RESPONSE=$(curl -s -S -o /dev/null -w "%{http_code}" -X PUT \
     -T "$TEMP_ZIP" \
     -H "x-ms-blob-type: BlockBlob" \
     -H "Content-Type: application/octet-stream" \
     "$UPLOAD_URL")

# --- 4. VERIFICATION & CLEANUP ---
if [ "$RESPONSE" == "201" ]; then
    echo "Upload Success (HTTP 201). Removing temporary local zip."
    rm "$TEMP_ZIP"
    exit 0
else
    echo "Upload Failed with HTTP status: $RESPONSE"
    echo "The local zip remains at $TEMP_ZIP for troubleshooting."
    exit 1
fi
