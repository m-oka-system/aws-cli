#!/bin/bash
set -euo pipefail

# 変数
CLUSTER_NAME="rails-cluster"
TASK_DEF_NAME="rails-app"
SUBNET_IDS=("subnet-0313a11c3f426e520","subnet-0f2667fd5467c6287")
SECURITY_GROUP_IDS=("sg-00861a1ded3a4bf73")
CMD="$1"
# CMD="db:create"
# CMD="db:migrate"

aws ecs run-task \
  --cluster $CLUSTER_NAME \
  --task-definition $TASK_DEF_NAME \
  --count 1 \
  --launch-type "FARGATE" \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_IDS],securityGroups=[$SECURITY_GROUP_IDS],assignPublicIp=ENABLED}" \
  --overrides '{"containerOverrides":[{"name":"web","command":["bundle","exec","rails","'$CMD'"]}]}'
  # --overrides file://run_task_db_migrate.json
