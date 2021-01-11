#!/bin/bash
set -euo pipefail

# 変数
ClousterName="docker"
TaskDefinitionName="docker-web"

aws ecs run-task \
  --cluster $ClousterName \
  --task-definition $TaskDefinitionName \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-0313a11c3f426e520,subnet-0f2667fd5467c6287],securityGroups=[sg-00861a1ded3a4bf73]}" \
  --overrides file://run_task_db_migrate.json
