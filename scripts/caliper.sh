echo -e "\n=== 步骤4: 性能测试 ==="
cd /root/ruc/caliper-benchmarks || exit

echo "启动Caliper测试..."
npx caliper launch manager \
  --caliper-workspace ./ \
  --caliper-networkconfig networks/fabric/test-network.yaml \
  --caliper-benchconfig benchmarks/samples/fabric/fabcar/config.yaml \
  --caliper-flow-only-test \
  --caliper-fabric-gateway-enabled