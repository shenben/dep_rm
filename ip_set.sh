#!/bin/bash
set -x
#configure IP,masks,gateway
sudo chattr -i /etc/network/interfaces
sudo chmod a+w /etc/network/interfaces
cat <<EOF > /etc/network/interfaces
auto ibp130s0
iface ibp130s0 inet static
    address 192.168.1.101
    netmask 255.255.255.0
    mtu 4092
EOF
sudo chmod 644 /etc/network/interfaces
sudo chattr +i /etc/network/interfaces
#restart networking
sudo systemctl restart networking # sudo /etc/init.d/networking restart

# sudo apt update && sudo apt install ifupdown

# sudo ip link set enp3s0f0 up
# ip a | grep enp3s0f0 
# sudo ethtool enp3s0f0

# sudo ethtool -i enp3s0f0  
# sudo lspci | grep -i ethernet 
# sudo dmesg | grep enp3s0f0