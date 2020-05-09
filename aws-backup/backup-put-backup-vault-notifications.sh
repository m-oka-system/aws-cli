#!/bin/bash

# variables
vaultName="EC2-Vault"
snsTopicArn="arn:aws:sns:ap-northeast-1:123456789012:AWSBackup-Topic"

# create notifications
aws backup put-backup-vault-notifications \
  --endpoint-url https://backup.ap-northeast-1.amazonaws.com \
  --backup-vault-name $vaultName \
  --sns-topic-arn $snsTopicArn \
  --backup-vault-events BACKUP_JOB_STARTED BACKUP_JOB_COMPLETED RESTORE_JOB_STARTED RESTORE_JOB_COMPLETED RECOVERY_POINT_MODIFIED

# show notifications
aws backup get-backup-vault-notifications \
  --backup-vault-name $vaultName

# delete notifications
aws backup delete-backup-vault-notifications \
  --endpoint-url https://backup.ap-northeast-1.amazonaws.com \
  --backup-vault-name $vaultName
