echo "Setting up static ip address"

#do this in installation
# move it to network-scripts folder
#cp -f wp_config_files/ifcfg-enp0s3 /etc/sysconfig/network-scripts/

# setup resolv.conf
#echo "nameserver 4.2.2.2" >> /etc/resolv.conf

# add DNS Name wp.snp.acit to hosts
# restart network
#systemctl restart network

#setup the shared folder

# do this in installation
# setup users
# echo "Creating user admin"
# useradd admin
# echo admin:P@ssw0rd | chpasswd
# usermod -aG wheel admin

# create ssh directory
echo "Creating directory"
sudo -u admin mkdir /home/admin/.ssh
sudo -u admin chmod 700 /home/admin/.ssh
sudo -u admin touch /home/admin/.ssh/authorized_keys
sudo -u admin chmod 600 /home/admin/.ssh/authorized_keys
echo "Adding public key to authorized keys"
cat wp_config_files/acit_admin_id_rsa.pub >> /home/admin/.ssh/authorized_keys

# install packages
yum install @core epel-release vim git tcpdump nmap-ncat wget curl -y

# update?
yum install update

##############################################
# FIREWALLD SETUP
##############################################
echo "Setting up Firewall"
firewall-cmd --zone=public --add-port=22/tcp --permanent
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=443/tcp --permanent

echo "Restarting the firewall"
systemctl restart firewalld

##############################################
# NGINX SETUP
##############################################
echo "Installing nginx"
yum install nginx -y

echo "Starting nginx"
systemctl start nginx

echo "Enabling nginx"
systemctl enable nginx

echo "Check nginx status"
systemctl status nginx

###########################################
# MARIADB SETUP
###########################################
yum install mariadb-server mariadb -y
systemctl start mariadb

# mysql_secure_installation

mysql -u root < wp_config_files/mariadb_security_config.sql

systemctl restart mariadb
systemctl enable mariadb
###########################################
# PHP SETUP
###########################################
yum install php php-mysql php-fpm -y

# uncomment line 763 in /etc/php.ini
cp -f wp_config_files/php.ini /etc/php.ini

# change /etc/php-fpm.d/www.conf
cp -f wp_config_files/www.conf /etc/php-fpm.d/www.conf

systemctl start php-fpm
systemctl enable php-fpm

cp -f wp_config_files/nginx.conf /etc/nginx/nginx.conf

systemctl restart nginx

#############################################
# WORDPRESS SETUP
#############################################
echo "Setting up Wordpress"

# DATABASE CONFIGURATION
echo "Configuring Database"

mysql -u root -pP@ssw0rd < wp_config_files/wp_mariadb_config.sql 

# SOURCE SETUP
# download wordpress
echo "Downloading wordpress from http://wordpress.org/latest.tar.gz"
wget http://wordpress.org/latest.tar.gz

# untar the archive
echo "Decompressing tar"
tar xzvf latest.tar.gz

echo "Copying file wp-config file for shared folder"

cp -f wp_config_files/wp-config.php wordpress/wp-config.php
#copy wp-config from some host/shared folder
# TODO do something here

echo "Doing rsync"
sudo rsync -avP wordpress/ /usr/share/nginx/html/

echo "Creating uploads folder"
sudo mkdir /usr/share/nginx/html/wp-content/uploads

echo "Setting permission on the wordpress source"
sudo chown -R admin:nginx /usr/share/nginx/html/*

echo "Wordpress successfully set up"
