#!/bin/bash

sudo apt-get update -y
sudo apt-get install -y apache2 git php5 php5-curl mysql-client curl php5-mysql

git clone https://github.com/itmo544/itmo544-444-fall2015.git

mv ./itmo544-444-fall2015/images /var/www/html/images
mv ./itmo544-444-fall2015/*.html /var/www/html
mv ./itmo544-444-fall2015/*.php /var/www/html

curl -sS https://getcomposer.org/installer | sudo php &> /tmp/getcomposer.txt
sudo php composer.phar require aws/aws-sdk-php &> /tmp/runcomposer.txt
sudo mv vendor /var/www/html &> /tmp/movevendor.txt

sudo php /var/www/html/setup.php &> /tmp/database-setup.txt

# (rw-------) The owner may read and write a file. All others have no rights. 
# A common setting for data files that the owner wants to keep private.
sudo chmod 600 /var/www/html/setup.php

echo "Hello! Sultan Here!" > /tmp/hello.txt
