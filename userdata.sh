#!/bin/bash

# Update system packages
apt-get update -y
apt-get upgrade -y

# Install Apache, MySQL, PHP, and other dependencies
apt-get install -y apache2 mysql-client php php-mysql libapache2-mod-php php-cli php-curl php-gd php-mbstring php-xml php-xmlrpc

# Enable Apache modules
a2enmod rewrite
systemctl restart apache2

# Download and extract WordPress
cd /var/www/html
wget https://wordpress.org/latest.tar.gz
tar -xf latest.tar.gz
rm latest.tar.gz
chown -R www-data:www-data wordpress

# Configure WordPress
cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php
sed -i "s/database_name_here/wordpress/g" /var/www/html/wordpress/wp-config.php
sed -i "s/username_here/admin/g" /var/www/html/wordpress/wp-config.php
sed -i "s/password_here/password1234/g" /var/www/html/wordpress/wp-config.php
sed -i "s/localhost/${aws_rds_cluster.main.endpoint}/g" /var/www/html/wordpress/wp-config.php

systemctl restart apache2