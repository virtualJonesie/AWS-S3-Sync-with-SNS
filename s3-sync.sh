#!/bin/bash
# -----------------------------------------------------------------------------
# s3-sync.sh
# This script syncs Magento code stored in an S3 bucket to the EBS-based local
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
LOG_FILE_PATH=~/s3-sync.log

# Sync Paths
S3_PATH=s3://acme-magento-server-files-dev-fail/acme/
LOCAL_PATH=/var/www/html/acme/

# AWS Configuration
AWS_REGION=us-east-2

# Simple Notification Service (SNS) Configuration
SNS_TOPIC_ARN=arn:aws:sns:us-east-2:614385033991:S3_Sync_Failures
SNS_TOPIC_SUBJECT="Magento Code S3 Failure"
SNS_TOPIC_MESSAGE="The Magento code S3 sync failed for server `hostname` at `date`."
# -----------------------------------------------------------------------------
# Script Body
# -----------------------------------------------------------------------------
# Log the start of the S3 sync for troubleshooting.
echo "`date` `hostname` Beginning S3 Sync" | tee -a ${LOG_FILE_PATH}
# Execute the S3 sync command.
/usr/bin/aws s3 sync --region ${AWS_REGION} ${S3_PATH} ${LOCAL_PATH} --no-follow-symlinks --quiet
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
