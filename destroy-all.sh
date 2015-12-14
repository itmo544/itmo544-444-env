#!/bin/bash

declare -a cleanupARR
declare -a cleanupLBARR
declare -a dbInstanceARR
declare -a ARN
declare -a s3

aws ec2 describe-instances --filter Name=instance-state-code,Values=16 --output table | grep InstanceId | sed "s/|//g" | tr -d ' ' | sed "s/InstanceId//g"

mapfile -t cleanupARR < <(aws ec2 describe-instances --filter Name=instance-state-code,Values=16 --output table | grep InstanceId | sed "s/|//g" | tr -d ' ' | sed "s/InstanceId//g")

echo "the output is ${cleanupARR[@]}"

aws ec2 terminate-instances --instance-ids ${cleanupARR[@]} 

echo "Cleaning up existing Load Balancers"
mapfile -t cleanupLBARR < <(aws elb describe-load-balancers --output json | grep LoadBalancerName | sed "s/[\"\:\, ]//g" | sed "s/LoadBalancerName//g")

echo "The LBs are ${cleanupLBARR[@]}"

LENGTH=${#cleanupLBARR[@]}
echo "ARRAY LENGTH IS $LENGTH"
for (( i=0; i<${LENGTH}; i++)); 
  do
  aws elb delete-load-balancer --load-balancer-name ${cleanupLBARR[i]} --output text
  sleep 1
done

# Delete existing RDS  Databases
# Note if deleting a read replica this is not your command 
mapfile -t dbInstanceARR < <(aws rds describe-db-instances --output json | grep "\"DBInstanceIdentifier" | sed "s/[\"\:\, ]//g" | sed "s/DBInstanceIdentifier//g" )

if [ ${#dbInstanceARR[@]} -gt 0 ]
   then
   echo "Deleting existing RDS database-instances"
   LENGTH=${#dbInstanceARR[@]}  

   # http://docs.aws.amazon.com/cli/latest/reference/rds/wait/db-instance-deleted.html
      for (( i=0; i<${LENGTH}; i++));
      do 
      aws rds delete-db-instance --db-instance-identifier ${dbInstanceARR[i]} --skip-final-snapshot --output text
      aws rds wait db-instance-deleted --db-instance-identifier ${dbInstanceARR[i]} --output text
      sleep 1
   done
fi

# Create Launchconf and Autoscaling groups

LAUNCHCONF=(`aws autoscaling describe-launch-configurations --output json | grep LaunchConfigurationName | sed "s/[\"\:\, ]//g" | sed "s/LaunchConfigurationName//g"`)

SCALENAME=(`aws autoscaling describe-auto-scaling-groups --output json | grep AutoScalingGroupName | sed "s/[\"\:\, ]//g" | sed "s/AutoScalingGroupName//g"`)

echo "The asgs are: " ${SCALENAME[@]}
echo "the number is: " ${#SCALENAME[@]}

if [ ${#SCALENAME[@]} -gt 0 ]
  then
echo "SCALING GROUPS to delete..."
#aws autoscaling detach-launch-
#aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $SCALENAME
aws autoscaling delete-launch-configuration --launch-configuration-name $LAUNCHCONF
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $SCALENAME --min-size 0 --max-size 0
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $SCALENAME
aws autoscaling delete-launch-configuration --launch-configuration-name $LAUNCHCONF
fi

echo "Cleaning up SNS"
#Delete SNS
mapfile -t ARN < <(aws sns list-topics --output json | grep TopicArn | sed "s/[\", ]//g" | sed "s/TopicArn//g" | sed "s/\://");
echo "Here is the list of SNS Topics: " ${ARN[@]}
if [ ${#ARN[@]} -gt 0 ]
   then
   echo "Deleting existing SNS TOPICS"
   LENGTH=${#ARN[@]}  
    for (( i=0; i<${LENGTH}; i++));
      do 
      aws sns delete-topic --topic-arn ${ARN[i]} --output text
	done
echo "Sucessfully deleted All SNS Topics";
fi

#Delete s3 buckets
#sudo apt-get install s3cmd
#s3cmd --configure

#FILES=(`s3cmd ls s3://mybucket | grep -v DIR | awk '{print $4}' | tr '\n' ' '`); 
#for FILENAME in ${FILES[*]}; 
#    do 
#	s3cmd del $FILENAME; 
#done

#DIRS=(`s3cmd ls s3://mybucket | grep DIR | awk '{print $2}' | tr '\n' ' '`) 
#for DIRNAME in ${DIRS[*]}; 
#    do 
#	s3cmd del --recursive $DIRNAME; 
#done
#source: http://anton.logvinenko.name/en/blog/how-to-delete-all-files-from-amazon-s3-bucket.html


#Remove # fro the following code in order to cleanup S3 bucket

#Delete S3 - If previously Failed
#mapfile -t s3 < <(aws s3 ls s3://mybucket --output json | grep DIR | awk '{print $2}' | tr '\n' ' ');
#echo "Here is the list of S3 bucket: " ${s3[@]}
#if [ ${#s3[@]} -gt 0 ]
#  then
#   echo "Deleting existing S3 buckets"
#   LENGTH=${#s3[@]}  
#
#      for (( i=0; i<${LENGTH}; i++));
#      do 
#	aws s3 rm ${s3[i]} --output text
#   done
#echo "Sucessfully deleted s3 buckets";
#fi

echo "All done."
