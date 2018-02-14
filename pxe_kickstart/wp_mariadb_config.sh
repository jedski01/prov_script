#!/bin/bash

#log to journal showing script start
systemd-cat -p "notice" -t wp_mariadb_config printf "%s" "wp_mariadb_config.sh start" 

#execute wp_mariadb_config.sql statements as the root mysql user, 
mysql -u root < mariadb_security_config.sql
systemctl restart mariadb 
mysql -u root -pP@ssw0rd < wp_mariadb_config.sql

#remember password for root hasn't been set yet

#Disable the wp_mariadb_config.service
sytemctl disable wp_mariadb_config.service

# delete the service and config files
rm -rf /wp_config_files

#log to journal showing script end
systemd-cat -p "notice" -t wp_mariadb_config printf "%s" "wp_mariadb_config.sh end" 
