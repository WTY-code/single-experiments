#!/bin/bash

SERVER1_IP=$1
SERVER1_PW=$2
SERVER2_IP=$3
SERVER2_PW=$4


cd /root/ruc/experiments/scripts || exit

echo "还原peer配置..."
python3 modify_docker_compose.py /root/ruc/fabric-samples/multiple-deployment/docker-compose-up-server1.yaml /root/ruc/experiments/config/core_origin.txt
python3 modify_docker_compose.py /root/ruc/fabric-samples/multiple-deployment/docker-compose-up-server2.yaml /root/ruc/experiments/config/core_origin.txt

echo "还原orderer配置..."
python3 modify_docker_compose.py /root/ruc/fabric-samples/multiple-deployment/docker-compose-up-server1.yaml /root/ruc/experiments/config/orderer_origin.txt
python3 modify_docker_compose.py /root/ruc/fabric-samples/multiple-deployment/docker-compose-up-server2.yaml /root/ruc/experiments/config/orderer_origin.txt

echo "还原configtx配置..."
python3 modify_config.py /root/ruc/fabric-samples/multiple-deployment/configtx.yaml /root/ruc/experiments/config/configtx-raft_origin.txt

echo "分发配置到server2..."
sshpass -p "$SERVER2_PW" scp /root/ruc/fabric-samples/multiple-deployment/docker-compose-up-server2.yaml root@$SERVER2_IP:/root/ruc/fabric-samples/multiple-deployment/
echo "分发完毕"