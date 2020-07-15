#!/usr/bin/env bash

set -e

function wait-efs-restore-complete () {
  # Wait until the EFS restore is complete
  local count=1
  local status=
  while [ "$status" != "COMPLETED" ]
  do
    sleep $sleepInterval
    status=$(aws backup describe-restore-job --region $region --restore-job-id $1 --query Status --output text)
    if [ $count -ge $maxSleepSecs ]; then
      # echo "$(date +%Y-%m-%d_%H-%M-%S):${efsName} のリストアがタイムアウトしました。"
      return 1
    fi
    count=$((count + 1))
  done
}


