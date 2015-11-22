#!/bin/bash

#Create Database
#aws rds create-db-instance --db-name customerrecords --db-instance-identifier mp1-sb --db-instance-class db.t1.micro --engine MySQL --engine-ver 5.6.23 --master-username controller --master-user-password letmein888 --allocated-storage 10 --vpc-security-group-ids sg-e30e4b84 --publicly-accessible

#Wait Untill Database is created
#aws rds wait db-instance-available --db-instance-identifier mp1-sb

#Create Read Replica Golden Copy
#aws rds create-db-instance-read-replica --db-instance-identifier mp1-sb-rr --source-db-instance-identifier mp1-sb --publicly-accessible

#Create an EndPoint
DBEndpoint=(`aws rds describe-db-instances --output text | grep ENDPOINT | sed -e "s/3306//g" -e "s/ //g" -e "s/ENDPOINT//g"`);
echo ${DBEndpoint[0]} #Store and Display Database Instance, not read replica

#chmod 755 ../itmo544-444-fall2015/setup.php
#sudo php ../itmo544-444-fall2015/setup.php

#Create table if not created by setup.php
	# Connect to database instance
		# Connect to database
			# Create table (Forget setup.php)
				# Show Schema 

mysql -h ${DBEndpoint[0]} -P 3306 -u controller -pletmein888  << EOF

use customerrecords;

CREATE TABLE items (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, uname VARCHAR(20) NOT NULL, email VARCHAR(20) NOT NULL, phone VARCHAR(20) NOT NULL, s3rawurl VARCHAR(255) NOT NULL, s3finishedurl VARCHAR(255) NOT NULL, filename VARCHAR(255) NOT NULL, status TINYINT(3)CHECK(state IN(0,1,2)), date DATETIME DEFAULT CURRENT_TIMESTAMP);

show tables;

EOF

echo "YAY!! It worked!!";
