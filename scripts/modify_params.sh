#!/bin/bash

SERVER1_IP=$1
SERVER1_PW=$2
SERVER2_IP=$3
SERVER2_PW=$4

cd /root/ruc/experiments/scripts || exit
# 步骤1：修改参数
echo "\n=== 修改参数 ==="
echo "修改server1配置..."
python3 modify_docker_compose.py /root/ruc/fabric-samples/multiple-deployment/docker-compose-up-server1.yaml /root/ruc/experiments/config/parameters_to_modify_peer.txt
python3 modify_docker_compose.py /root/ruc/fabric-samples/multiple-deployment/docker-compose-up-server1.yaml /root/ruc/experiments/config/parameters_to_modify_orderer.txt

echo "修改server2配置..."
python3 modify_docker_compose.py /root/ruc/fabric-samples/multiple-deployment/docker-compose-up-server2.yaml /root/ruc/experiments/config/parameters_to_modify_peer.txt
python3 modify_docker_compose.py /root/ruc/fabric-samples/multiple-deployment/docker-compose-up-server2.yaml /root/ruc/experiments/config/parameters_to_modify_orderer.txt

echo "修改configtx配置..."
python3 modify_config.py /root/ruc/fabric-samples/multiple-deployment/configtx.yaml /root/ruc/experiments/config/parameters_to_modify_configtx.txt

echo "分发配置到server2..."
sshpass -p "$SERVER2_PW" scp /root/ruc/fabric-samples/multiple-deployment/docker-compose-up-server2.yaml root@$SERVER2_IP:/root/ruc/fabric-samples/multiple-deployment/

# 步骤2：生成创世区块
echo -e "\n=== 生成创世区块 ==="
cd /root/ruc/fabric-samples/multiple-deployment || exit

echo "生成创世区块..."
configtxgen -profile TwoOrgsChannel -outputBlock ./channel-artifacts/genesis.block -channelID mychannel -configPath /root/ruc/fabric-samples/multiple-deployment

echo "分发区块到server2..."
sshpass -p "$SERVER2_PW" scp ./channel-artifacts/genesis.block root@$SERVER2_IP:/root/ruc/fabric-samples/multiple-deployment/channel-artifacts/
