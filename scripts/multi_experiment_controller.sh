#!/bin/bash

# 验证参数
if [ $# -ne 4 ]; then
    echo "usage: $0 <server1_ip> <server1_pw> <server2_ip> <server2_pw>"
    exit 1
fi

# 读取参数
SERVER1_IP=$1
SERVER1_PW=$2
SERVER2_IP=$3
SERVER2_PW=$4


# 步骤0：参数还原
echo -e "\n=== 参数还原 ==="
cd /root/ruc/experiments/scripts || exit
./roll_back_params.sh "$SERVER1_IP" "$SERVER1_PW" "$SERVER2_IP" "$SERVER2_PW"
# sleep 60
# exit 0
sleep 5
# 步骤1&步骤2：修改参数 生成创世区块
./modify_params.sh "$SERVER1_IP" "$SERVER1_PW" "$SERVER2_IP" "$SERVER2_PW"
sleep 5

# 步骤3：启动网络
echo -e "\n=== 步骤3: 启动网络 ==="
echo "启动Fabric网络..."
cd /root/ruc/fabric-samples/multiple-deployment || exit
./deploy_fabric.sh "$SERVER1_IP" "$SERVER1_PW" "$SERVER2_IP" "$SERVER2_PW"

sleep 10

# # 步骤4：运行测试
# echo -e "\n=== 步骤4: 性能测试 ==="
# cd /root/ruc/caliper-benchmarks || exit

# echo "启动Caliper测试..."
# npx caliper launch manager \
#   --caliper-workspace ./ \
#   --caliper-networkconfig networks/fabric/test-network.yaml \
#   --caliper-benchconfig benchmarks/samples/fabric/fabcar/config.yaml \
#   --caliper-flow-only-test \
#   --caliper-fabric-gateway-enabled

# # 步骤5：停止网络
# echo -e "\n=== 步骤5: 清理环境 ==="
# cd /root/ruc/fabric-samples/multiple-deployment || exit

# echo "停止Fabric网络..."
# ./networkdown.sh "$SERVER1_IP" "$SERVER1_PW" "$SERVER2_IP" "$SERVER2_PW"

# echo -e "\n=========================="
# echo "实验流程已完成!"
# echo "=========================="