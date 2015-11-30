#!/bin/bash

#################################

#Mini Project 1

#Database username: controller
#Database password: letmein888
#Database name: customerrecords
#Database table name: items 

#################################

echo "===============================================================";
echo "Cleaning up previous Instances, Load Blacer, Autoscale, and RDS";
echo "===============================================================";

#./cleanup-def.sh
./cleanup.sh

# declare an array in bash
declare -a instanceARRAY

mapfile -t instanceARRAY < <(aws ec2 run-instances --image-id ami-d05e75b8 --count 3 --instance-type t2.micro --key-name itmo-linux-troubleshootingkey --security-group-ids sg-e30e4b84 --subnet-id subnet-c856a5f5 --associate-public-ip-address --iam-instance-profile Name=phpdeveloperRole --user-data file://install-env.sh --output table | grep InstanceId | sed "s/|//g" | sed "s/ //g" | sed "s/InstanceId//g")

echo ${instanceARRAY[@]}

#aws ec2 wait instance-running --instance-ids ${instanceARRAY[@]}
#echo "instances are running"

echo "==========================================================";
echo "Instance created successfully. Now creating load balancers";
echo "==========================================================";

ELBURL=(`aws elb create-load-balancer --load-balancer-name itmo544sb-lb --listeners Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80 --subnets subnet-c856a5f5 --security-groups sg-e30e4b84 --output=text`); echo $ELBURL
echo "=========================================================";
echo -e "ELB Launching is finished and now sleeping for 25 seconds"
for i in {0..25}; do echo -ne '.'; sleep 1;done
echo "...............................";

# register instances with load balancer
aws elb register-instances-with-load-balancer --load-balancer-name itmo544sb-lb --instances ${instanceARRAY[@]}

# create health check for load balancer
aws elb configure-health-check --load-balancer-name itmo544sb-lb --health-check Target=HTTP:80/index.html,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=3

# create cookie stickiness policy for load balancer
#aws elb create-lb-cookie-stickiness-policy --load-balancer-name itmo544sb-lb --policy-name cookie-policy --cookie-expiration-period 90
#aws elb set-load-balancer-policies-of-listener --load-balancer-name itmo544sb-lb --load-balancer-port 80 --policy-names cookie-policy

#echo -e "Wait 25 seconds for ELB"
#for i in {0..25}; do echo -ne '.'; sleep 1; done

echo "................";
echo "Creating Autoscale and Cloudwatch Metrics";
echo "=========================================";

# Create Launch Configuration and Auto Scale
#aws autoscaling create-launch-configuration --launch-configuration-name itmo544-launch-config --image-id ami-d05e75b8 --instance-type t2.micro --key-name itmo-linux-troubleshootingkey --security-groups sg-e30e4b84 --user-data file://install-env.sh --iam-instance-profile phpdeveloperRole

#aws autoscaling create-auto-scaling-group --auto-scaling-group-name itmo-544-extended-auto-scaling-group-2 --launch-configuration-name itmo544-launch-config --load-balancer-name itmo544sb-lb --health-check-type ELB --min-size 1 --max-size 3 --desired-capacity 2 --default-cooldown 600 --health-check-grace-period 120 --vpc-zone-identifier subnet-c856a5f5


#Scaling policy for Cloud Watch
#SCALEUP=(`aws autoscaling put-scaling-policy --auto-scaling-group-name itmo-544-extended-auto-scaling-group-2 --policy-name scaleup3 --scaling-adjustment 3 --adjustment-type ChangeInCapacity --cooldown 60`)

#SCALEDOWN=(`aws autoscaling put-scaling-policy --auto-scaling-group-name itmo-544-extended-auto-scaling-group-2 --policy-name scaledown3 --scaling-adjustment -3 --adjustment-type ChangeInCapacity --cooldown 60`)


#Cloud Watch Using Auto Scale Policy
#aws cloudwatch put-metric-alarm --alarm-name cpumon30 --alarm-description "Alarm when CPU exceeds 30 percent" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 60 --threshold 30 --comparison-operator GreaterThanOrEqualToThreshold  --dimensions "Name=AutoScalingGroupName,Value=itmo-544-extended-auto-scaling-group-2" --evaluation-periods 1 --alarm-actions $SCALEUP --unit Percent

#aws cloudwatch put-metric-alarm --alarm-name cpumon10 --alarm-description "Alarm when CPU drops below 10 percent" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 60 --threshold 10 --comparison-operator LessThanOrEqualToThreshold  --dimensions "Name=AutoScalingGroupName,Value=itmo-544-extended-auto-scaling-group-2" --evaluation-periods 1 --alarm-actions $SCALEDOWN --unit Percent


echo "=====================================";
echo "Creating database, wait 10-15 minutes";
echo "=====================================";

#Create Database
#aws rds create-db-instance --db-name customerrecords --db-instance-identifier mp1-sb --db-instance-class db.t1.micro --engine MySQL --engine-ver 5.6.23 --master-username controller --master-user-password letmein888 --allocated-storage 10 --vpc-security-group-ids sg-e30e4b84 --publicly-accessible

#Wait Untill Database is created
#aws rds wait db-instance-available --db-instance-identifier mp1-sb

#Create Read Replica Golden Copy
#aws rds create-db-instance-read-replica --db-instance-identifier mp1-sb-rr --source-db-instance-identifier mp1-sb --publicly-accessible

#Create table
#sudo php ../itmo544-444-fall2015/setup.php

#Create an EndPoint
DBEndpoint=(`aws rds describe-db-instances --output text | grep ENDPOINT | sed -e "s/3306//g" -e "s/ //g" -e "s/ENDPOINT//g"`);
echo ${DBEndpoint[0]}

#Create table if not created by setup.php
	# Connect to database instance
		# Connect to database
			# Create table
				# Show Schema 

#mysql -h ${DBEndpoint[0]} -P 3306 -u controller -pletmein888  << EOF

#use customerrecords;

#CREATE TABLE IF NOT EXISTS items (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, uname VARCHAR(20) NOT NULL, email VARCHAR(30) NOT NULL, phone VARCHAR(20) NOT NULL, s3rawurl VARCHAR(255) NOT NULL, s3finishedurl VARCHAR(255) NOT NULL, filename VARCHAR(255) NOT NULL, status TINYINT(3)CHECK(state IN(0,1,2)), date DATETIME DEFAULT CURRENT_TIMESTAMP);

#show tables;

#EOF

echo "==============================================";
echo "MP1 successfully completed. Now working on mp2";
echo "==============================================";


############################################
# MP 2 - SNS

#Create A Topic
#Display Name Attributes
#Subscribe
#Publish (Topic Arn hard coded)
#Create Cloud watch metric

############################################

#CREATE A TOPIC
#ARN=(`aws sns create-topic --name mp2`)
#echo "This is the ARN: $ARN"

#DISPLAY NAME ATTRIBUTE
#aws sns set-topic-attributes --topic-arn $ARN --attribute-name DisplayName --attribute-value mp2

#SUBSCRIBE
#aws sns subscribe --topic-arn $ARN --protocol sms --notification-endpoint 16303621844

#echo -e "Wait 45 seconds for Pending Confirmation"
#for i in {0..45}; do echo -ne ':)'; sleep 1; done

#PUBLISH
#aws sns publish --topic-arn "arn:aws:sns:us-east-1:882985546393:mp2" --message "Congratulations, you sucessfully subscribed"

#SEND SMS WHN CLOUD WATCH METRIC TRIGGERED
#aws cloudwatch put-metric-alarm --alarm-name cpumon30 --alarm-description "Alarm when CPU exceeds 30 percent" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 60 --threshold 30 --comparison-operator GreaterThanOrEqualToThreshold  --dimensions "Name=AutoScalingGroupName,Value=itmo-544-extended-auto-scaling-group-2" --evaluation-periods 1 --alarm-actions $ARN --unit Percent

#aws cloudwatch put-metric-alarm --alarm-name cpumon10 --alarm-description "Alarm when CPU drops below 10 percent" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 60 --threshold 10 --comparison-operator LessThanOrEqualToThreshold  --dimensions "Name=AutoScalingGroupName,Value=itmo-544-extended-auto-scaling-group-2" --evaluation-periods 1 --alarm-actions $ARN --unit Percent

echo -e "Wait 2.5 minutes for ELB"
for i in {0..150}; do echo -ne '.'; sleep 1; done

echo "";
echo "=================================================================";
echo "Everything is successfully created. Now launching ELB in Firefox";
echo "=================================================================";

#Launch Load balancer in Web Browser
firefox $ELBURL
