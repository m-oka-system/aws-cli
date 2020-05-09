#!/bin/bash
servers=$(cat server-list.csv | awk -F, 'NR>1')

for i in ${servers[@]}; do
  # Variables
  region=$(echo $i | cut -d , -f 1)
  dbInstanceIdentifier=$(echo $i | cut -d , -f 2)
  dbInstanceClass=$(echo $i | cut -d , -f 3)
  dbSubnetGroupName=$(echo $i | cut -d , -f 4)
  dbParameterGroupName=$(echo $i | cut -d , -f 5)
  optionGroupName=$(echo $i | cut -d , -f 6)
  vpcSecurityGroups=$(echo $i | cut -d , -f 7)
  allocatedStorage=$(echo $i | cut -d , -f 8)
  dbName=$(echo $i | cut -d , -f 9)
  dbUserName=$(echo $i | cut -d , -f 10)
  dbUserPassword=$(echo $i | cut -d , -f 11)
  multAz=$(echo $i | cut -d , -f 12)
  
  # Create RDS instances
  # You can't set the AvailabilityZone parameter if the DB instance is a Multi-AZ deployment.
  aws rds create-db-instance \
    --db-instance-identifier $dbInstanceIdentifier \
    --db-instance-class $dbInstanceClass \
    --db-subnet-group-name $dbSubnetGroupName \
    --db-parameter-group-name $dbParameterGroupName \
    --option-group-name $optionGroupName\
    --vpc-security-group-ids $vpcSecurityGroups \
    --allocated-storage $allocatedStorage \
    --engine MySQL \
    --engine-version 5.7 \
    --db-name $dbName \
    --master-username $dbUserName \
    --master-user-password $dbUserPassword \
    --no-publicly-accessible \
    --backup-retention-period 2 \
    --preferred-backup-window "19:00-20:00" \
    --preferred-maintenance-window "Sat:20:00-Sat:21:00" \
    --auto-minor-version-upgrade \
    --availability-zone $region"a" \
    --no-multi-az \
    --deletion-protection
done
