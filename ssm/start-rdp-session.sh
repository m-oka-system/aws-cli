#!/bin/bash
set -euo pipefail

# 変数
INSTANCE_ID="$*"

if [ "$#" -ne 1 ]; then
  echo  "インスタンスIDを引数に指定してください。"
  exit 1
fi

# RDPセッションを開始(Session Manager Pluginのインストール要)
# https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
aws ssm start-session --target $INSTANCE_ID --document-name AWS-StartPortForwardingSession --parameters "portNumber=3389, localPortNumber=13389"
