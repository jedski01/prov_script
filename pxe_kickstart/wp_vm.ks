###### Installer Configuration #####################################################
# Use network installation replace with basesearch and releasever variables
url --url="https://mirror.its.sfu.ca/mirror/CentOS/7/os/x86_64/"

# License agreement
eula --agreed

#enable EPEL in order to install additional packages
repo --name="epel" --baseurl=http://download.fedoraproject.org/pub/epel/$releasever/$basearch

# Use graphical install
text

#Turn up logging
logging level=debug

# Reboot after installation
reboot

#Don't run keyboard / language / location / network setup on first boot
firstboot --disable
###### End Installer Configuration #################################################

###### Locale Configuration ########################################################
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'

# System language
lang en_CA.UTF-8

# System timezone
timezone America/Vancouver --isUtc
###### End Locale Configuration ####################################################

###### User and Auth Configuration #################################################
# System authorization information
auth --passalgo=sha512 --enableshadow

# Root password : P@ssw0rd
# generated with python3 -c 'import crypt; print(crypt.crypt("P@ssw0rd", crypt.mksalt(crypt.METHOD_SHA512)))'
rootpw --iscrypted $6$AXjWn6Bck0thdvVH$tFrdiRgKK7BLH0a8Bl0oFUd/mPrDLTJuuwn4YgY.QishhTKFS/lOjaclTR3xko/uZRQR31cKLxMLSk1HZzoZk.

# admin password : P@ssw0rd
user --name=admin --password=$6$AXjWn6Bck0thdvVH$tFrdiRgKK7BLH0a8Bl0oFUd/mPrDLTJuuwn4YgY.QishhTKFS/lOjaclTR3xko/uZRQR31cKLxMLSk1HZzoZk. --iscrypted --gecos="admin" --groups="wheel"

###### End User and Auth Configuration #################################################

###### Network Configuration #######################################################
network  --bootproto=static --device=enp0s3 --gateway=192.168.254.1 --ip=192.168.254.10 --nameserver=4.2.2.2 --netmask=255.255.255.0 --ipv6=auto --activate
network  --hostname=localhost.localdomain

###### End Network Configuration ###################################################

###### Disk Setup ##################################################################
clearpart --all
autopart #--type=plain

# System bootloader configuration (note location=mbr puts boot loader in ESP since UEFI)
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=sda
autopart --type=lvm

###### End Disk Setup ##################################################################

###### Security Configuration ######################################################
firewall --enabled --http --ssh --service=tftp
selinux --permissive
###### End Security Configuration ##################################################

###### System services #############################################################
services --enabled=sshd,ntpd,chronyd,dhcpd
###### End System services #########################################################


###### Pre-Installation Script #########################################################
###### End Pre-Installation Script #####################################################

###### Package Installation ############################################################
%packages
@core
@base 
epel-release
vim
chrony
git
kernel-devel
kernel-headers
dkms
gcc
gcc-c++
kexec-tools
ntp
dhcp
syslinux-tftpboot
tftp-server
xinetd
nginx
tcpdump
nmap-ncat
wget
curl
%end
###### End Package Installation ########################################################

###### Post-Installation Script ########################################################
%post --log=/root/ks-post.log
#!/bin/bash

#Update System
yum -y update

#Copy ssh authorized keys to new image
#Set ownership and permission of admin authorized keys
#chmod -R u=rw,g=,o= /home/admin/.ssh
#chown -R admin /home/admin/.ssh
#chgrp -R admin /home/admin/.ssh
#chmod u=rwx,g=,o= /home/admin/.ssh

# create ssh directory
echo "Creating directory"
sudo -u admin mkdir /home/admin/.ssh
sudo -u admin chmod 700 /home/admin/.ssh
sudo -u admin touch /home/admin/.ssh/authorized_keys
sudo -u admin chmod 600 /home/admin/.ssh/authorized_keys
echo "Adding public key to authorized keys"
cat wp_config_files/acit_admin_id_rsa.pub >> /home/admin/.ssh/authorized_keys

#Turn Down Swapiness since its an SSD disk
echo "vm.swappiness = 10" >> /etc/sysctl.conf

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
echo "Starting nginx"
systemctl start nginx

echo "Enabling nginx"
systemctl enable nginx

echo "Check nginx status"
systemctl status nginx

systemctl restart nginx

###########################################
# PHP SETUP
###########################################
yum install php php-mysql php-fpm -y

# uncomment line 763 in /etc/php.ini
cp -f wp_config_files/php.ini /etc/php.ini

# change /etc/php-fpm.d/www.conf
# TODO need to get this from PXE SERVER
cp -f wp_config_files/www.conf /etc/php-fpm.d/www.conf

systemctl start php-fpm
systemctl enable php-fpm

# TODO need to get this from PXE SERVER
cp -f wp_config_files/nginx.conf /etc/nginx/nginx.conf


#############################################
# WORDPRESS SETUP
#############################################
echo "Setting up Wordpress"

# DATABASE CONFIGURATION
echo "Configuring Database"

#TODO cannot add this yet
#mysql -u root -pP@ssw0rd < wp_config_files/wp_mariadb_config.sql 

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


#Install Virtualbox Guest Additions
mkdir vbox_cd
mount /dev/sr1 ./vbox_cd
./vbox_cd/VBoxLinuxAdditions.run
umount ./vbox_cd
rmdir ./vbox_cd

#Sudo Modifications
#Allow all wheel members to sudo all commands without a password by uncommenting line from /etc/sudoers
sed -i 's/^#\s*\(%wheel\s*ALL=(ALL)\s*NOPASSWD:\s*ALL\)/\1/' /etc/sudoers
#Enable sudo over ssh without a terminal
sed -i 's/^\(Defaults    requiretty\)/#\1/' /etc/sudoers

#tftp configuration: enable tftp by changing disabled from yes to no
sed -i 's/\s*\(disable =\s*\)yes/\1no/' /etc/xinetd.d/tftp

#Demonstration of copying remote file 
curl -o /root/rhel_7_installation_manual.pdf https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/pdf/System_Administrators_Guide/Red_Hat_Enterprise_Linux-7-System_Administrators_Guide-en-US.pdf

#Allow read and write by admin to /usr/share/nginx/html
chown -R nginx:wheel /usr/share/nginx/html
chmod -R ug+w /usr/share/nginx/html
 
%end
###### End Post-Installation Script ####################################################


