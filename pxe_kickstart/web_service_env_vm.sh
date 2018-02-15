#!/bin/bash

vboxmanage () { VBoxManage.exe "$@"; }

# check if acit_4640_pxe is running 
# if it is not run it
vboxmanage startvm acit_4640_pxe

until [[ $(ssh -q pxe exit && echo "online") == "online" ]] ; do
  sleep 10s
  echo "waiting for pxe server vm to come online"
done

scp wp_ks.cfg pxe:/usr/share/nginx/html
scp -r ../scripted_config/wp_config_files pxe:/usr/share/nginx/html/
scp wp_mariadb_config.service wp_mariadb_config.sh pxe:/usr/share/nginx/html/wp_config_files
ssh pxe 'sudo chown nginx:wheel /usr/share/nginx/html/wp_ks.cfg'
ssh pxe 'sudo chmod ugo+r /usr/share/nginx/html/wp_ks.cfg'
ssh pxe 'chmod ugo+rx /usr/share/nginx/html/wp_config_files'
ssh pxe 'chmod -R ugo+r /usr/share/nginx/html/wp_config_files/*'

./wp_vm_setup.sh