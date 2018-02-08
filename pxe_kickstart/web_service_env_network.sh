#!/bin/bash

vboxmanage () { VBoxManage.exe "$@"; }

echo "adding port forward rule to sys_net_prov NAT network"
vboxmanage natnetwork modify --netname sys_net_prov \
    --port-forward-4 "ssh:tcp:[]:50222:[192.168.254.5]:22"
echo "done"