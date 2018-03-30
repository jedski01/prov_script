#!/bin/bash

vboxmanage () { VBoxManage.exe "$@"; }

# Cludge to get the path of the directory where the vbox file is stored. 
# Used to create hard disk file in same directory as vbox file without using 
# absolute paths

# declare vm variables
declare vm_name=Wordpress_VM_automated
declare size_in_mb=10000
# this one is temporary
declare iso_file_path="../isos/CentOS-7-x86_64-Minimal-1708.iso"
declare memory_mb=1280
declare network_name=sys_net_prov
declare group_name=""
# and so is this one


# attach sys_net_prov network
vboxmanage modifyvm acit_4640_pxe\
  --nic1 natnetwork\
  --nat-network1 sys_net_prov
  
# check if acit_4640_pxe is running 
# if it is not run it
vboxmanage startvm acit_4640_pxe

until [[ $(ssh -q pxe exit && echo "online") == "online" ]] ; do
  sleep 10s
  echo "waiting for pxe server vm to come online"
done

# transfer configuration files to pxe server
./web_service_env_vm.sh

#check if the vm exists
#remove it if it exists
for vm in `vboxmanage list vms | awk '{print $1}' | tr -d '\015' | tr -d '\"'`
do
    if [ "$vm" == "$vm_name" ]
    then
        echo "Removing existing Virtual Machine"
        # vboxmanage controlvm $vm_name poweroff
        vboxmanage unregistervm $vm_name --delete
    fi
done


# create vm in default location
echo "Creating Virtual Machine"
vboxmanage createvm --name $vm_name --register

# grab the vms folder
################################################################################
# vboxmanage showvminfo displays line with the path to the config file -> grep "Config file returns it
declare vm_info=$(VBoxManage.exe showvminfo "${vm_name}")
declare vm_conf_line=$(echo "${vm_info}" | grep "Config file")

# Windows: the extended regex [[:alpha:]]:(\\[^\]+){1,}\\.+\.vbox matches everything that is a path 
# i.e. C:\ followed by anything not a \ and then repetitions of that ending in a filename with .vbox extension
declare vm_conf_file=$( echo "${vm_conf_line}" | grep -oE '[[:alpha:]]:(\\[^\]+){1,}\\.+\.vbox' )

# strip leading text and trailing filename from config file line to leave directory of VM
declare vbox_directory_win="$(echo ${vm_conf_file} | sed 's/Config file:\s\+// ; s/\\[^\]\+\.vbox$//')"

# WSL commands will use the linux path, whereas Windows native commands (most
# importantly VBoxManage.exe) will use the windows style path.
echo "${vbox_directory_win}"
################################################################################

# create virtual hard drive
echo "Creating virtual hard drive"
vboxmanage createhd --filename "${vbox_directory_win}\\${vm_name}.vdi"\
    --size $size_in_mb\
    -variant Standard

echo "Adding storage controllers"
declare hd_ctrl=hd_ctrl
declare dvd_ctrl=dvd_ctrl

echo "Adding IDE controller for optical drive"
vboxmanage storagectl $vm_name\
    --name $dvd_ctrl\
    --add ide\
    --bootable on

echo "Adding SATA controller for hard disk image"
vboxmanage storagectl $vm_name\
    --name $hd_ctrl\
    --add sata\
    --bootable on

# attach Hard disk and specify its ssd
echo "Attaching hard disk to VM"
vboxmanage storageattach $vm_name\
    --storagectl $hd_ctrl\
    --port 0\
    --device 0\
    --type hdd\
    --medium "${vbox_directory_win}\\${vm_name}.vdi"\
    --nonrotational on

# Attach the VirtualBox Guest Additions ISO file
vboxmanage storageattach $vm_name --storagectl $dvd_ctrl --port 1 --device 0 --type dvddrive --medium "C:/Program Files/Oracle/VirtualBox/VBoxGuestAdditions.iso"

#configure vm
echo "Reconfiguring the VM"
vboxmanage modifyvm $vm_name\
    --groups "${group_name}"\
    --ostype "RedHat_64"\
    --cpus 1\
    --hwvirtex on\
    --nestedpaging on\
    --largepages on\
    --firmware bios\
    --nic1 natnetwork\
    --nat-network1 "${network_name}"\
    --cableconnected1 on\
    --audio none\
    --boot1 disk\
    --boot2 net\
    --memory "${memory_mb}" \
    --macaddress1 "020000000001"

echo "VM successfully created"

echo "Starting vm"
vboxmanage startvm ${vm_name}