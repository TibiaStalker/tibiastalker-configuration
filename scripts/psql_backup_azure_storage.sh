#!/bin/bash

# Variables
DB_NAME="character_finder"
DB_USER="admin"
DB_HOST="0.0.0.0"
DB_PORT="5432"
DB_PASSWORD="XXXXXXXXXXX"
BACKUP_DIR="/root/backup"
BACKUP_DATE=`date +%Y-%m-%d-%H%M%S`
BACKUP_FILE_NAME="${DB_NAME}_${BACKUP_DATE}.xz"
BACKUP_FILE="${BACKUP_DIR}/${BACKUP_FILE_NAME}"
AZURE_STORAGE_ACCOUNT="YYYYYYY"
AZURE_CONTAINER_NAME="backup"
SAS_TOKEN="ZZZZZZZZZZZ"
AZCOPY_PATH="/usr/local/bin"

# Creating direction if not exist
echo "Dumping database to ${BACKUP_FILE}" 

if [ ! -d "${BACKUP_DIR}" ]; then
    mkdir -p "${BACKUP_DIR}"
fi 

# Create dump
PGPASSWORD="${DB_PASSWORD}" pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -w --format=custom | xz > "${BACKUP_FILE}"

# Check for dump existing
if [ $? -eq 0 ]; then
    echo "Dump created correctly: ${BACKUP_FILE}"
else
    echo "Dump creating failed"
    exit 1
fi

# Send dump to Azure Storage
${AZCOPY_PATH}/azcopy copy ${BACKUP_FILE} "https://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/${AZURE_CONTAINER_NAME}/${BACKUP_FILE_NAME}?${SAS_TOKEN}" --block-blob-tier "Archive"

# Check for sending file to azure storage complete
if [ $? -eq 0 ]; then
    echo "Dump sended to Azure Storage correctly"
else
    echo "Dump sending to Azure Storage failed"
    exit 1
fi

# Optional: remove local dump copy
rm ${BACKUP_FILE}