#!/bin/bash

region="ap-northeast-1"
hostName="WEB01"
snsTopicArn="arn:aws:sns:ap-northeast-1:xxxxxxxxxxxx:MyTopic"
instanceId=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$hostName" --query "Reservations[].Instances[].InstanceId" --output text)

aws cloudwatch put-metric-alarm \
  --region $region \
  --alarm-name "recover-ec2-instance-"$hostName \
  --alarm-description "recover-ec2-instance-"$hostName \
  --alarm-actions \
      arn:aws:automate:ap-northeast-1:ec2:recover \
      $snsTopicArn \
  --namespace AWS/EC2 \
  --metric-name StatusCheckFailed_System \
  --dimensions Name=InstanceId,Value=$instanceId \
  --comparison-operator GreaterThanThreshold \
  --statistic Maximum \
  --period 60 \
  --threshold 1 \
  --evaluation-periods 2