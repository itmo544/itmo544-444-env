#! /bin/bash

#MP 2 - SNS

#Create Topic
ARN=(`aws sns create-topic --name mp2`)
echo "This is the ARN: $ARN"

#Display Name Attribute
aws sns set-topic-attributes --topic-arn $ARN --attribute-name DisplayName --attribute-value mp2

#Subscribe
aws sns subscribe --topic-arn $ARN --protocol sms --notification-endpoint 16303621844

echo -e "Wait 30 seconds for Pending Confirmation"
for i in {0..30}; do echo -ne ':)'; sleep 1; done

#Publish
aws sns publish --topic-arn "arn:aws:sns:us-east-1:882985546393:mp2" --message "best code ever"


