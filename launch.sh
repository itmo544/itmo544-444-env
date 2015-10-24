#!/bin/bash

./cleanup.sh

# declare an array in bash
declare -a instanceARRAY

mapfile -t instanceARRAY < <(aws ec2 run-instances --image-id ami-d05e75b8 --count 3 --instance-type t2.micro --key-name itmo-linux-troubleshootingkey --security-group-ids sg-e30e4b84 --subnet-id subnet-c856a5f5 --associate-public-ip-address --iam-instance-profile Name=phpdeveloperRole --user-data file://install-env.sh --output table | grep InstanceId | sed "s/|//g" | sed "s/ //g" | sed "s/InstanceId//g")


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

#Comment out launch config and auto scale untill php, sql, and cloudwatch work under progress 
# creating launch configuration and auto scalling
#aws autoscaling create-launch-configuration --launch-configuration-name itmo544-launch-config --image-id ami-d05e75b8 --instance-type t2.micro --key-name itmo-linux-troubleshootingkey --security-groups sg-e30e4b84 --user-data file://install-env.sh --iam-instance-profile phpdeveloperRole

#aws autoscaling create-auto-scaling-group --auto-scaling-group-name itmo-544-extended-auto-scaling-group-2 --launch-configuration-name itmo544-launch-config --load-balancer-name itmo544sb-lb --health-check-type ELB --min-size 1 --max-size 3 --desired-capacity 2 --default-cooldown 600 --health-check-grace-period 120 --vpc-zone-identifier subnet-c856a5f5

