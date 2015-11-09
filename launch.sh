#!/bin/bash

./cleanup.sh

# declare an array in bash
declare -a instanceARRAY

mapfile -t instanceARRAY < <(aws ec2 run-instances --image-id $1 --count $2 --instance-type $3 --key-name $4 --security-group-ids $5 --subnet-id $6 --associate-public-ip-address --iam-instance-profile $7 --user-data file://install-env.sh --output table | grep InstanceId | sed "s/|//g" | sed "s/ //g" | sed "s/InstanceId//g")


echo ${instanceARRAY[@]}

aws ec2 wait instance-running --instance-ids ${instanceARRAY[@]}
echo "instances are running"

ELBURL=(`aws elb create-load-balancer --load-balancer-name itmo544sb-lb --listeners Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80 --subnets subnet-c856a5f5 --security-groups sg-e30e4b84 --output=text`); echo $ELBURL
echo -e "\nELB Launching is finished and now sleeping for 25 seconds"
for i in {0..25}; do echo -ne '.'; sleep 1;done
echo "\n"

# register instances with load balancer
aws elb register-instances-with-load-balancer --load-balancer-name itmo544sb-lb --instances ${instanceARRAY[@]}

# create health check for load balancer
aws elb configure-health-check --load-balancer-name itmo544sb-lb --health-check Target=HTTP:80/index.html,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=3

# create cookie stickiness policy for load balancer
aws elb create-lb-cookie-stickiness-policy --load-balancer-name itmo544sb-lb --policy-name cookie-policy --cookie-expiration-period 90
aws elb set-load-balancer-policies-of-listener --load-balancer-name itmo544sb-lb --load-balancer-port 80 --policy-names cookie-policy

echo -e "\wait 3 minutes for ELB before it starts loading in browser"
for i in {0..100}; do echo -ne '.'; sleep 1; done


# Create Launch Configuration and Auto Scale
aws autoscaling create-launch-configuration --launch-configuration-name itmo544-launch-config --image-id ami-d05e75b8 --instance-type t2.micro --key-name itmo-linux-troubleshootingkey --security-groups sg-e30e4b84 --user-data file://install-env.sh --iam-instance-profile phpdeveloperRole

aws autoscaling create-auto-scaling-group --auto-scaling-group-name itmo-544-extended-auto-scaling-group-2 --launch-configuration-name itmo544-launch-config --load-balancer-name itmo544sb-lb --health-check-type ELB --min-size 1 --max-size 3 --desired-capacity 2 --default-cooldown 600 --health-check-grace-period 120 --vpc-zone-identifier subnet-c856a5f5


#Scaling policy for Cloud Watch
SCALEUP=(`aws autoscaling put-scaling-policy --auto-scaling-group-name itmo-544-extended-auto-scaling-group-2 --policy-name scaleup3 --scaling-adjustment 3 --adjustment-type ChangeInCapacity --cooldown 60`)

SCALEDOWN=(`aws autoscaling put-scaling-policy --auto-scaling-group-name itmo-544-extended-auto-scaling-group-2 --policy-name scaledown3 --scaling-adjustment -3 --adjustment-type ChangeInCapacity --cooldown 60`)


#Cloud Watch Using Auto Scale Policy
aws cloudwatch put-metric-alarm --alarm-name cpumon30 --alarm-description "Alarm when CPU exceeds 30 percent" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 60 --threshold 30 --comparison-operator GreaterThanOrEqualToThreshold  --dimensions "Name=AutoScalingGroupName,Value=itmo-544-extended-auto-scaling-group-2" --evaluation-periods 1 --alarm-actions $SCALEUP --unit Percent

aws cloudwatch put-metric-alarm --alarm-name cpumon10 --alarm-description "Alarm when CPU drops below 10 percent" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 60 --threshold 10 --comparison-operator LessThanOrEqualToThreshold  --dimensions "Name=AutoScalingGroupName,Value=itmo-544-extended-auto-scaling-group-2" --evaluation-periods 1 --alarm-actions $SCALEDOWN --unit Percent


#Create Database
aws rds create-db-instance --db-name customerrecords --db-instance-identifier mp1-sb --db-instance-class db.t1.micro --engine MySQL --master-username controller --master-user-password letmein888 --allocated-storage 5 --vpc-security-group-ids sg-e30e4b84 --publicly-accessible

#Wait Untill Database is created and then print
aws rds wait db-instance-available --db-instance-identifier mp1-sb

echo -e "\wait 30 seconds. Database tables creation is under progress.."
for i in {0..30}; do echo -ne '.'; sleep 1; done

#Create table if not created by setup.php
	# Connect to database instance
		# Connect to database
			# Create table if doesn't exists
				# Show Schema 

mysql -h mp1-sb.cq1yqny3b3jn.us-east-1.rds.amazonaws.com -P 3306 -u controller -pletmein888  << EOF

use customerrecords;

CREATE TABLE IF NOT EXISTS items(id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, uname VARCHAR2(20) NOT NULL, email VARCHAR2(20) NOT NULL, phone VARCHAR2(20) NOT NULL, s3rawurl VARCHAR2(255) NOT NULL, s3finishedurl VARCHAR2(255) NOT NULL, jpgfilename VARCHAR2(255) NOT NULL, status TINYINT(3)CHECK(state IN(0,1,2)), tdate DATETIME DEFAULT CURRENT_TIMESTAMP);

show tables;

EOF

echo -e "\wait 30 seonds for ELB before it starts loading in browser"
for i in {0..30}; do echo -ne '.'; sleep 1; done

#Launch Load balancer in Web Browser
firefox $ELBURL


