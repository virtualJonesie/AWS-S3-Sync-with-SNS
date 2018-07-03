#!/bin/bash
# -----------------------------------------------------------------------------
# s3-sync.sh
# This script syncs files stored in an S3 bucket to the EBS-based local
# storage.
#
# This script is designed to be run as a cron job for on-going synchronization,
# and/or as part of the User Data in a launch config at deplyoment.
#
# Created: 2018.06.20 by David Jones david.jones@greenpages.com
# Updated: 
# -----------------------------------------------------------------------------
# Configuration Variable Definiitons
# -----------------------------------------------------------------------------
# Log File Configuration
LOG_FILE_PATH=/var/log/s3-sync.log

# Sync Paths
S3_PATH=s3://[BUCKET_NAME]/[FOLDER_NAME]/
LOCAL_PATH=/var/www/html/

# AWS Configuration
AWS_REGION=us-east-1

# Simple Notification Service (SNS) Configuration
SNS_TOPIC_ARN=[SNS_TOPIC_ARN]
SNS_TOPIC_SUBJECT="S3 Sync Failure"
SNS_TOPIC_MESSAGE="The S3 sync failed for server `hostname` at `date`."
# -----------------------------------------------------------------------------
# Script Body
# -----------------------------------------------------------------------------
# Check to see if the script is already running.
for pid in $(pidof -x s3-sync.sh); do
#    echo "`date` $pid"
    if [ $pid != $$ ]; then
        echo "`date` `hostname` AWS S3 Sync script is already running with PID $pid" | tee -a ${LOG_FILE_PATH}
        exit 1
    fi
done

# Check to see if the command is already running.
#for pid in $(pidof -x /usr/bin/aws); do
# Use pgrep -f "/usr/bin/aws s3 sync"
for pid in $(pgrep -f "/usr/bin/aws s3 sync"); do
    echo "`date` $pid"
    if [ $pid != $$ ]; then
        echo "`date` `hostname` AWS S3 Sync process is already running with PID $pid" | tee -a ${LOG_FILE_PATH}
        exit 1
    fi
done

# Log the start of the S3 sync for troubleshooting.
echo "`date` `hostname` Beginning S3 Sync" | tee -a ${LOG_FILE_PATH}
# Execute the S3 sync command.
/usr/bin/aws s3 sync ${S3_PATH} ${LOCAL_PATH} --no-follow-symlinks --quiet
# Capture the return code form the S3 sync command.
RETURN_CODE=$?
if [ $RETURN_CODE -eq 0 ]; then
        # Command completed successfully.
        # Log the successful completion of the S3 sync.
        echo "`date` `hostname` S3 Sync Completed Successfully!" | tee -a ${LOG_FILE_PATH}
else
        # Command failed.
        # Log the failure for troubleshooting purposes.
        echo "`date` `hostname` S3 Sync Failed with Return Value ${RETURN_CODE}" | tee -a ${LOG_FILE_PATH}
        # Publish the failure to an SNS topic for alerting.
        /usr/bin/aws sns publish --region ${AWS_REGION} --topic-arn ${SNS_TOPIC_ARN} --subject "${SNS_TOPIC_SUBJECT}" --message "${SNS_TOPIC_MESSAGE}"

fi
