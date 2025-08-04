#!/bin/bash
set -eux
# curl -fsSL https://get.docker.com | sudo bash
# sudo apt install $(cat manual_packages.txt)

function docker_daemon_sock_issue(){
# For Debian, The docker installer uses iptables for nat. Unfortunately Debian uses nftables. You can convert the entries over to nftables or just setup Debian to use the legacy iptables.
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
# dockerd, should start fine after switching to iptables-legacy.
sudo service docker start
}

function base_ins(){
    # Install golang
    wget https://go.dev/dl/go1.21.13.linux-amd64.tar.gz
    rm -rf /usr/local/go && tar -C /usr/local -xzf go1.21.13.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    # verify that golang has been installed
    export PATH=$PATH:/usr/local/go/bin
    . ~/.bashrc && go version

    # install dependency
    apt install pkg-config libseccomp-dev 

    # # clone ctr runtime repo and compile
    mkdir -p ~/go/src/github.com && cd ~/go/src/github.com
    git clone https://github.com/switch-container/runc.git opencontainers/runc
    git clone https://github.com/switch-container/containerd.git containerd/containerd
    git clone https://github.com/switch-container/go-criu.git checkpoint-restore/go-criu
    git clone https://github.com/switch-container/faasd.git openfaas/faasd
    git clone https://github.com/switch-container/faas-provider.git openfaas/faas-provider
    git clone https://github.com/switch-container/faas-cli.git openfaas/faas-cli

    cd opencontainers/runc && make runc && sudo env "PATH=$PATH" make install && cd -
    cd containerd/containerd && make BUILDTAGS=no_btrfs && sudo make install && cd -
    cd openfaas/faasd && make local && sudo make install && cd -
    cd openfaas/faas-cli && make local-install && cp ~/go/bin/faas-cli /usr/local/bin/faas-cli && cd -
    sudo chown id_17:rdmatestbench-PG * -R

}


function conf_net(){
    ARCH=amd64
CNI_VERSION=v1.3.0
mkdir -p /opt/cni/bin
curl -sSL https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-${ARCH}-${CNI_VERSION}.tgz | tar -xz -C /opt/cni/bin
mkdir -p /etc/cni/net.d/
cat >/etc/cni/net.d/10-openfaas.conflist <<EOF
{
    "cniVersion": "0.4.0",
    "name": "openfaas-cni-bridge",
    "plugins": [
      {
        "type": "bridge",
        "bridge": "openfaas0",
        "isGateway": true,
        "ipMasq": true,
        "ipam": {
            "type": "host-local",
            "subnet": "10.62.0.0/16",
            "dataDir": "/var/run/cni",
            "routes": [
                { "dst": "0.0.0.0/0" }
            ]
        }
      },
      {
        "type": "firewall"
      }
    ]
}
EOF

cat >/etc/cni/net.d/99-loopback.conf <<EOF
{
    "cniVersion": "0.3.1",
    "type": "loopback"
}
EOF

}
function criu_ins(){
    cd /root
    git clone https://github.com/switch-container/criu.git
    # make sure that the branch is on `switch`
    cd criu
    apt install libprotobuf-dev libprotobuf-c-dev protobuf-c-compiler protobuf-compiler python3-protobuf iproute2 libcap-dev libnl-3-dev libnet-dev
    make -j16 install-criu
    # the output binary is located at /root/criu/criu/criu and /usr/local/sbin/criu
    mkdir -p /root/downloads && cp /root/criu/criu/criu /root/downloads/switch-criu
}
function fun_ins(){
cd /root/downloads
wget -O pkgs.tar.gz https://cloud.tsinghua.edu.cn/f/4644dbac9e3a4b309c50/?dl=1
# Note than you cannot change this directory, unless you modify the faasd
mkdir -p /var/lib/faasd/ && tar xf pkgs.tar.gz -C /var/lib/faasd
}

function fr_ins(){
# rm -rf /root/faasnap
mkdir /root/faasnap && cd /root/faasnap  && git clone https://github.com/switch-container/faasnap.git
cd /root/faasnap && \
wget -O vmlinux https://cloud.tsinghua.edu.cn/f/ef649f94564e4b40a1c2/?dl=1 && \
wget -O firecracker https://cloud.tsinghua.edu.cn/f/fa90c80489c842608a51/?dl=1 && \
chmod +x vmlinux firecracker
export PATH=$PATH:/usr/local/go/bin
# build the faasnap daemon
go install github.com/go-swagger/go-swagger/cmd/swagger@latest
cd /root/faasnap/faasnap && /root/go/bin/swagger generate server -f api/swagger.yaml
go get ./... && go build cmd/faasnap-server/main.go

cd /root/faasnap && mkdir -p rootfs && cd rootfs && \
wget -O debian-nodejs-rootfs.ext4.zip https://cloud.tsinghua.edu.cn/f/0b2144137441475495a3/?dl=1 && \
wget -O debian-python-rootfs.ext4.zip https://cloud.tsinghua.edu.cn/f/72ba9d8cdaac4abf8856/?dl=1
apt install unzip && unzip debian-nodejs-rootfs.ext4.zip && unzip debian-python-rootfs.ext4.zip

# cd /root/criu && git checkout master && make clean && make -j16 install-criu && \
#  cp /root/criu/criu/criu /root/downloads/raw-criu && git checkout switch && make clean
}

function oth_ins(){
cd /root
git clone https://github.com/switch-container/rdma-server.git
apt install libibverbs-dev rdma-core librdmacm-dev
cd rdma-server && make
# the output binary is pseudo-mm-rdma-server

# Dependency to configure CXL (or PMem).
# Note that ndctl is only necessary for PMem, so if you are using CXL you can only install daxctl
apt install numactl daxctl ndctl

cd /root
git clone https://github.com/switch-container/utils.git
git clone --branch huang https://github.com/switch-container/faasd-testdriver.git
mkdir -p /root/test && cd /root/test
ln -s /root/faasd-testdriver/ /root/test/faasd-testdriver && \
 ln -s /root/rdma-server/pseudo-mm-rdma-server /root/test/pseudo-mm-rdma-server && \
 ln -s /root/utils/stack.yml /root/test/stack.yml && \
 ln -s /root/faasd-testdriver/functions/template/ /root/test/template

# download two datasets (Azure and Huawei traces)
mkdir -p /root/downloads && cd /root/downloads && \
  wget https://azurepublicdatasettraces.blob.core.windows.net/azurepublicdatasetv2/azurefunctions_dataset2019/azurefunctions-dataset2019.tar.xz && \
  wget https://sir-dataset.obs.cn-east-3.myhuaweicloud.com/datasets/public_dataset/public_dataset.zip
# unzip the dataset
mkdir azurefunction-dataset2019 && tar xf azurefunctions-dataset2019.tar.xz -C azurefunction-dataset2019 && unzip public_dataset.zip

apt install python3.10-venv
# You should use exactly the following path for venv, unless you modified the test-common.sh in utils repo.
cd /root && mkdir venv && cd venv && python3 -m venv faasd-test
source /root/venv/faasd-test/bin/activate && pip install pyyaml gevent requests pandas numpy matplotlib
}

base_ins
conf_net
criu_ins
fun_ins
fr_ins
oth_ins