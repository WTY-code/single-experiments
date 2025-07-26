#!/bin/bash

# define color
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

usage() {
    echo "usage: $0 <path/to/xxx.yaml> <path/to/parameters_to_modify.txt>"
    echo "example: $0 /root/ruc/fabric-samples/test-network/bft-config/configtx.yaml /root/ruc/experiments/config/parameters_to_modify.txt"
    exit 1
}

# check args
if [ "$#" -ne 2 ]; then
    usage
fi

# check yaml file and parameters to modify list
if [ ! -f "$1" ]; then
    echo -e "${RED}ERROR: $1 NOT exist!${NC}"
    usage
fi

if [ ! -f "$2" ]; then
    echo -e "${RED}ERROR: $2 NOT exist!${NC}"
    usage
fi

CONFIGTX_PATH="$1"
PARAMETERS_PATH="$2"

# execute command and check execution status
execute_command() {
    local step_name="$1"
    local command="$2"
    local dir="$3"
    
    echo -e "${YELLOW}STEP ${step_name}${NC}"
    echo -e "COMMAND: ${command}"
    
    if [ -n "$dir" ]; then
        echo "SWITCH TO: $dir"
        cd "$dir" || {
            echo -e "${RED}EEROR: Can NOT switch to ${dir}${NC}"
            return 1
        }
    fi
    
    eval "$command"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERROR: STEP ${step_name} FAILED!${NC}"
        return 1
    else
        echo -e "${GREEN}SUCCESS: STEP ${step_name} FINISHED!${NC}"
        return 0
    fi
}

# workflow
main() {
    # 1. stop the current network
    execute_command "1. STOP NETWORK" "./network_add.sh down" "/root/ruc/fabric-samples/test-network" || return 1
    sleep 2
    
    # 2. modify parameters
    execute_command "2. MODIFY PARAMETERS" "python3 /root/ruc/experiments/scripts/modify_config.py \"$CONFIGTX_PATH\" \"$PARAMETERS_PATH\"" "" || return 1
    sleep 2

    # 3. start network
    execute_command "3. START NETWORK" "./network_add.sh up createChannel -bft" "/root/ruc/fabric-samples/test-network" || return 1
    sleep 2

    # 4. deploy chiancode
    execute_command "4. DEPLOY CHAINCODE" "./network_add.sh deployCC -ccn fabcar -ccp ../../caliper-benchmarks/src/fabric/samples/fabcar/go -ccl go -ccap" "/root/ruc/fabric-samples/test-network" || return 1
    sleep 2

    # 5. start monior
    execute_command "5. START MONITOR" "./start_monitors.sh" "/root/ruc/experiments/scripts" || return 1
    
    # 6. execute test
    execute_command "6. EXECUTE TEST" "npx caliper launch manager --caliper-workspace ./ --caliper-networkconfig networks/fabric/test-network.yaml --caliper-benchconfig benchmarks/samples/fabric/fabcar/config.yaml --caliper-flow-only-test --caliper-fabric-gateway-enabled | tee >(grep -A 30 \"### All test results ###\" > summary_table.log)" "/root/ruc/caliper-benchmarks" || return 1
    sleep 2

    # 7. stop monitor
    execute_command "7. STOP MONITOR" "./stop_monitors.sh" "/root/ruc/experiments/scripts" || return 1
    sleep 2

    # 8. process metrics
    execute_command "8. PROCESS METRICS" "python3 metrics_process.py" "/root/ruc/experiments/scripts" || return 1
    
    # 9. move summary table
    execute_command "9. MOVE SUMMARY TABLE" "./move_summary_table.sh" "/root/ruc/experiments/scripts" || return 1
    
    # 10. copy parameters_to_modified.txt
    execute_command "10. COPY parameters_to_modified.txt" "./move_parameter_modified_list.sh" "/root/ruc/experiments/scripts" || return 1
    
    echo -e "${GREEN}ALL STEPS FINIDHED!${NC}"
}

main