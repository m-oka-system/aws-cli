#!/bin/bash
set -euo pipefail

# 変数
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLUSTER_NAME="rails-cluster"
TASK_DEF_NAME="rails-app"
SERVICE_NAME="rails-service"
SUBNET_IDS=("subnet-0313a11c3f426e520","subnet-0f2667fd5467c6287")
SECURITY_GROUP_IDS=("sg-00861a1ded3a4bf73")

# 確認メッセージ
echo "Region:${AWS_DEFAULT_REGION}"
read -r -p "サービスを作成します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# メイン処理
function main() {

  . ${SCRIPT_DIR}/lib/ecs

  LATEST_TASK_DEFINITION=$(aws ecs list-task-definitions --family-prefix $TASK_DEF_NAME --query "taskDefinitionArns[-1]" --output text)
  aws ecs create-service \
    --cluster $CLUSTER_NAME \
    --service-name $SERVICE_NAME \
    --task-definition $LATEST_TASK_DEFINITION \
    --desired-count 1 \
    --launch-type "FARGATE" \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_IDS],securityGroups=[$SECURITY_GROUP_IDS],assignPublicIp=ENABLED}"

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
