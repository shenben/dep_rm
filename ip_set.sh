#!/bin/bash
set -x
#configure IP,masks,gateway
sudo chattr -i /etc/network/interfaces
sudo chmod a+w /etc/network/interfaces
cat <<EOF > /etc/network/interfaces
auto ibp130s0
iface ibp130s0 inet static
    address 192.168.1.102
    netmask 255.255.255.0
    mtu 4092
EOF
sudo chmod 644 /etc/network/interfaces
sudo chattr +i /etc/network/interfaces
#restart networking
sudo systemctl restart networking # sudo /etc/init.d/networking restart

# sudo apt update && sudo apt install ifupdown