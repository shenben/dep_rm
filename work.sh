# !/bin/bash
set -eux
# cd /root/utils
rm -rf /root/utils
pushd /root
git clone https://github.com/shenben/utils.git
cd /root/utils
# bash machine-prepare.sh --mem-pool rdma --nic  ibp130s0
# kill -9 $(ps aux | grep containerd | awk '{print $2}')
# systemctl stop docker 
# systemctl stop containerd 
# popd

# cd /root/test/faasd-testdriver
# # w1, will run about 30 m
# python gen_trace.py -w 1
# # w2, will run about 30 m
# python gen_trace.py -w 2
# # huawei, will run about 1 hour
# python gen_trace.py -w huawei --dataset /root/downloads/public_dataset/csv_files/requests_minute
# # azure, will run about 1 hour
# python gen_trace.py -w azure --dataset /root/downloads/azurefunction-dataset2019

# cd /root/test/faasd-testdriver
# python gen_trace.py -w 1
# cd /root/utils
# # then start run test for the above generated workload
# bash test.sh --clean && bash test.sh --mem 32 cxl-w32 && bash test.sh --clean
# bash test.sh --gc 3 --mem 32 --baseline --start-method cold cold-w32 && bash test.sh --clean
# bash test.sh --gc 3 --mem 32 --baseline --start-method criu criu-w32 && bash test.sh --clean
# # # For FaaSnap and REAP, make sure the daemon (i.e., main) has been killed
# # bash test.sh --gc 3 --mem 32 --baseline --start-method faasnap faasnap-w32 && bash test.sh --clean && pkill main && pkill firecracker
# bash test.sh --gc 3 --mem 32 --baseline --start-method reap reap-w32 && bash test.sh --clean && pkill main && pkill firecracker