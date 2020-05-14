#!/bin/bash

HostName=WEB01
aws iam delete-role-policy --role-name $HostName"_IAMROLE" --policy-name $HostName"_IAMPOLICY"
aws iam delete-role --role-name $HostName"_IAMROLE"
aws iam delete-policy --policy-arn $IAMPOLICY_ARN
aws iam delete-instance-profile --instance-profile-name $HostName"_IAMROLE"