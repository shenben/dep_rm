# # lsblk
sudo mkfs -t ext4 /dev/sdb
sudo mkdir -p /mnt/data
sudo mount /dev/sdb /mnt/data
sudo chmod 777 /mnt/data -R
pushd /mnt/data
sudo apt update
sudo apt install  libncurses-dev gawk flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf llvm
git clone https://github.com/switch-container/linux.git
ln -s $(pwd)/linux $HOME/linux
cd linux
cp ~/config_trenv .config
make -j$(nproc)
make modules -j$(nproc)
make headers -j$(nproc)
sudo make headers_install
sudo make modules_install -j$(nproc)
sudo make install
popd
# reboot