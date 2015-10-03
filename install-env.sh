#!/bin/bash

sudo apt-get update -y
sudo apt-get install -y apache2 git 

git clone https://github.com/itmo544/itmo544-444-fall2015.git

cp ./itmo544-444-fall2015/images /var/www/html/images
cp ./itmo544-444-fall2015/index.html /var/www/html
cp ./itmo544-444-fall2015/page2.html /var/www/html

echo "Hello! Sultan Here!" > /tmp/hello.txt