#!/bin/bash

vboxmanage () { VBoxManage.exe "$@"; }

scp wp_ks.cfg pxe:/usr/share/nginx/html
scp -r ../scripted_config/wp_config_files pxe:/usr/share/nginx/html/
scp wp_mariadb_config.service wp_mariadb_config.sh pxe:/usr/share/nginx/html/wp_config_files
#ssh pxe 'sudo chown nginx:wheel /usr/share/nginx/html/wp_ks.cfg'
#git stssh pxe 'chmod ugo+r /usr/share/nginx/html/wp_ks.cfg'
ssh pxe 'chmod ugo+rx /usr/share/nginx/html/wp_config_files'
ssh pxe 'chmod -R ugo+r /usr/share/nginx/html/wp_config_files/*'