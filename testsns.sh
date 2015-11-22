#! /bin/bash

#MP 2 - SNS

#CREATE A TOPIC
ARN=(`aws sns create-topic --name mp2`)
echo "This is the ARN: $ARN"

#DISPLAY NAME ATTRIBUTE
aws sns set-topic-attributes --topic-arn $ARN --attribute-name DisplayName --attribute-value mp2

#SUBSCRIBE
aws sns subscribe --topic-arn $ARN --protocol sms --notification-endpoint 16303621844

echo -e "Wait 30 seconds for Pending Confirmation"
for i in {0..30}; do echo -ne ':)'; sleep 1; done

#PUBLISH
aws sns publish --topic-arn "arn:aws:sns:us-east-1:882985546393:mp2" --message "best code ever"

#SEND SMS WHN CLOUD WATCH METRIC TRIGGERED
aws cloudwatch put-metric-alarm --alarm-name cpumon30 --alarm-description "Alarm when CPU exceeds 30 percent" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 60 --threshold 30 --comparison-operator GreaterThanOrEqualToThreshold  --dimensions "Name=AutoScalingGroupName,Value=itmo-544-extended-auto-scaling-group-2" --evaluation-periods 1 --alarm-actions $ARN --unit Percent

aws cloudwatch put-metric-alarm --alarm-name cpumon10 --alarm-description "Alarm when CPU drops below 10 percent" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 60 --threshold 10 --comparison-operator LessThanOrEqualToThreshold  --dimensions "Name=AutoScalingGroupName,Value=itmo-544-extended-auto-scaling-group-2" --evaluation-periods 1 --alarm-actions $ARN --unit Percent

# Everything is working
