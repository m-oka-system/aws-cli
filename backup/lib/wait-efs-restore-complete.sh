#!/usr/bin/env bash

set -e

function wait-efs-restore-complete () {
  # Wait until the EFS restore is complete
  count=1
  while [ "$status" != "COMPLETED" ]
  do
    echo "$(date +%Y-%m-%d_%H-%M-%S):EFSのリストア完了まで待機します。Count:$count"
    sleep $sleepInterval
    status=$(aws backup describe-restore-job --region $region --restore-job-id $1 --query Status --output text)
    if [ $count -ge $maxSleepSecs ]; then
      echo "$(date +%Y-%m-%d_%H-%M-%S):EFSのリストアがタイムアウトしました。処理を終了します。"
      break
    fi
    i=$((i + 1))
  done
}


