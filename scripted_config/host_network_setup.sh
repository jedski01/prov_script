#!/bin/bash

vboxmanage () { VBoxManage.exe "$@"; }

declare network_name=sys_net_prov
declare network_address=192.168.254.0
declare cidr_bits=24

echo
echo "Creating Virtualbox NAT Network"
echo "Name: $network_name"
echo "IP address: $network_address/$cidr_bits"
echo

# check if nat network of this name already exists
# if it is remove it and create a new one
# do this by iterating over the natnetwork list.
# Just get the name of nat network

# The last segment of the pipeline removes the carriage return since awk preserves it
for output in `vboxmanage natnetwork list | grep -e "Name" | awk '{print $2}' | tr -d '\015'`
do
    if [ "$output" = "$network_name" ]
    then
        echo "Removing existing NAT network"
        vboxmanage natnetwork remove --netname $network_name;
        break
    fi
done

echo "Adding NAT Network"
vboxmanage natnetwork add --netname $network_name --network "$network_address/$cidr_bits" --dhcp off

declare wordpress_vm_ip=192.168.254.10

echo "Adding Port Forwarding Rules for $wordpress_vm_ip"

# Add the portforwarding rules

vboxmanage natnetwork modify --netname $network_name \
    --port-forward-4 "ssh:tcp:[]:50022:[$wordpress_vm_ip]:22"

vboxmanage natnetwork modify --netname $network_name \
    --port-forward-4 "http:tcp:[]:50080:[$wordpress_vm_ip]:80"

vboxmanage natnetwork modify --netname $network_name \
    --port-forward-4 "https:tcp:[]:50443:[$wordpress_vm_ip]:443"

echo "NAT Network successfully created"