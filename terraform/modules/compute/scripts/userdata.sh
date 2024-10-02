#!/bin/bash

echo "Update/Install required OS packages"
yum update -y
yum install -y httpd wget php-fpm php-mysqli php-json php php-devel telnet tree git

echo "Deploy PHP info app"
cd /tmp
git clone https://github.com/kledsonhugo/app-dynamicsite
cp /tmp/app-dynamicsite/phpinfo.php /var/www/html/index.php

echo "Config Apache WebServer"
usermod -a -G apache ec2-user
chown -R ec2-user:apache /var/www
chmod 2775 /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;

echo "Start Apache WebServer"
systemctl enable httpd
service httpd restart