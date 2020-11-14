#!/bin/bash
set -euo pipefail

# 変数
SERVER_FILE="db-list.csv"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# サーバ一覧のファイルを1行ずつ読み込んで配列へ格納
mapfile -t SERVER_ARRAY < <(sed 1d $SERVER_FILE | sed '/^#/d')

# 確認メッセージ
for array in "${SERVER_ARRAY[@]}"; do echo $array; done
read -r -p "上記サーバを作成します。よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "処理を終了します." ; exit ;; esac

# 関数を定義
# シングルAZ
function create_db_instance_single_az() {
  aws rds create-db-instance \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --db-instance-class $DB_INSTANCE_CLASS \
    --availability-zone ${AWS_DEFAULT_REGION}a \
    --no-multi-az \
    --db-subnet-group-name db-subnet \
    --db-parameter-group-name default.mysql8.0 \
    --option-group-name default:mysql-8-0 \
    --vpc-security-group-ids $VPC_SECURITY_GROUP_NAME \
    --storage-type $STORAGE_TYPE \
    --allocated-storage $ALLOCATED_STORAGE \
    --storage-encrypted \
    --engine $DB_ENGINE \
    --engine-version $DB_ENGINE_VERSION \
    --license-model $LICENSE_MODEL \
    --db-name $DB_NAME \
    --port $PORT \
    --master-username $DB_USER_NAME \
    --master-user-password $DB_USER_PASSWORD \
    --no-publicly-accessible \
    --copy-tags-to-snapshot \
    --backup-retention-period 2 \
    --preferred-backup-window "19:00-20:00" \
    --preferred-maintenance-window "Sat:20:00-Sat:21:00" \
    --enable-performance-insights \
    --performance-insights-retention-period 7 \
    --monitoring-interval 60 \
    --monitoring-role-arn arn:aws:iam::${ACCOUNT_ID}:role/rds-monitoring-role \
    --enable-cloudwatch-logs-exports ["$LOGS_EXPORTS"] \
    --auto-minor-version-upgrade \
    --deletion-protection \
    --tags Key=Name,Value=$DB_INSTANCE_IDENTIFIER Key=evn,Value=dev
}

# マルチAZ
function create_db_instance_multi_az() {
  aws rds create-db-instance \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --db-instance-class $DB_INSTANCE_CLASS \
    --multi-az \
    --db-subnet-group-name db-subnet \
    --db-parameter-group-name default.mysql8.0 \
    --option-group-name default:mysql-8-0 \
    --vpc-security-group-ids $VPC_SECURITY_GROUP_NAME \
    --storage-type $STORAGE_TYPE \
    --allocated-storage $ALLOCATED_STORAGE \
    --storage-encrypted \
    --engine $DB_ENGINE \
    --engine-version $DB_ENGINE_VERSION \
    --license-model $LICENSE_MODEL \
    --db-name $DB_NAME \
    --port $PORT \
    --master-username $DB_USER_NAME \
    --master-user-password $DB_USER_PASSWORD \
    --no-publicly-accessible \
    --copy-tags-to-snapshot \
    --backup-retention-period 2 \
    --preferred-backup-window "19:00-20:00" \
    --preferred-maintenance-window "Sat:20:00-Sat:21:00" \
    --enable-performance-insights \
    --performance-insights-retention-period 7 \
    --monitoring-interval 60 \
    --monitoring-role-arn arn:aws:iam::${ACCOUNT_ID}:role/rds-monitoring-role \
    --enable-cloudwatch-logs-exports ["$LOGS_EXPORTS"] \
    --auto-minor-version-upgrade \
    --deletion-protection \
    --tags Key=Name,Value=$DB_INSTANCE_IDENTIFIER Key=evn,Value=dev
}

for i in "${SERVER_ARRAY[@]}"; do
  # 変数に格納
  DB_INSTANCE_IDENTIFIER=$(echo $i | cut -d , -f 1)
  DB_INSTANCE_CLASS=$(echo $i | cut -d , -f 2)
  VPC_SECURITY_GROUP_NAME=$(echo $i | cut -d , -f 3)
  STORAGE_TYPE=$(echo $i | cut -d , -f 4)
  ALLOCATED_STORAGE=$(echo $i | cut -d , -f 5)
  DB_ENGINE=$(echo $i | cut -d , -f 6)
  DB_ENGINE_VERSION=$(echo $i | cut -d , -f 7)
  PORT=$(echo $i | cut -d , -f 8)
  DB_NAME=$(echo $i | cut -d , -f 9)
  DB_USER_NAME=$(echo $i | cut -d , -f 10)
  DB_USER_PASSWORD=$(echo $i | cut -d , -f 11)
  MULTI_AZ=$(echo $i | cut -d , -f 12)

  case "$DB_ENGINE" in
    sqlserver*)
      LOGS_EXPORTS='"error"'
      LICENSE_MODEL="license-included"
    ;;
    mysql)
      LOGS_EXPORTS='"error","general","slowquery"'
      LICENSE_MODEL="general-public-license"
    ;;
    oracle*)
      LOGS_EXPORTS='"error","general","audit","slowquery"'
      LICENSE_MODEL="license-included"
    ;;
  esac

  # Create RDS instances
  if [ "$MULTI_AZ" = "true" ]; then
    create_db_instance_multi_az
  else
    create_db_instance_single_az
  fi

done
