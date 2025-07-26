#!/bin/bash

EXPERIMENT_HOME="/root/ruc/experiments"
SCRIPTS_DIR="$EXPERIMENT_HOME/scripts"
METRICS_DIR="$EXPERIMENT_HOME/metrics"
LOGS_DIR="$EXPERIMENT_HOME/logs"
CONFIG_PATH="$EXPERIMENT_HOME/config"
# LISTS_DIR=$CONFIG_PATH
PORTS_FILE="$EXPERIMENT_HOME/config/container_port.txt"
PEER_METRICS_LIST="$CONFIG_PATH/peer_metrics_list.txt"
ORDERER_METRICS_LIST="$CONFIG_PATH/orderer_metrics_list.txt"
INTERVAL=5

mkdir -p "$METRICS_DIR/docker"
mkdir -p "$METRICS_DIR/fabric"
# mkdir -p "$METRICS_DIR/lists"

# check container_port.txt
if [ ! -f "$PORTS_FILE" ]; then
    echo "Error: Container ports file not found at $PORTS_FILE"
    exit 1
fi

# get port from PORTS FILE
get_container_port() {
    local container_name=$1
    grep -E "^$container_name\s+" "$PORTS_FILE" | awk '{print $2}'
}

# get all containers' ID and name, exclude chaincode container
get_fabric_containers() {
    docker ps --format '{{.ID}} {{.Names}}' | grep -v 'dev-peer' | grep -E 'peer|orderer'
}

# start monitor
start_monitoring() {
    local container_id=$1
    local container_name=$2
    
    # get operations port from PORTS FILE
    local metrics_port
    metrics_port=$(get_container_port "$container_name")
    
    if [ -z "$metrics_port" ]; then
        echo "Warning: No port found for container $container_name in $PORTS_FILE"
        return
    fi
    
    # set parameters according to node type
    if [[ $container_name == *"peer"* ]]; then
        # Peer node
        local metrics_list="$PEER_METRICS_LIST"
    elif [[ $container_name == *"orderer"* ]]; then
        # Orderer node
        local metrics_list="$ORDERER_METRICS_LIST"
    else
        echo "Unknown container type: $container_name"
        return
    fi
    
    # check if metrics list exists
    if [ ! -f "$metrics_list" ]; then
        echo "Error: Metrics list file not found: $metrics_list"
        return
    fi
    
    # create output dir
    local fabric_output="$METRICS_DIR/fabric/$container_name"
    local docker_output="$METRICS_DIR/docker/$container_name"
    mkdir -p "$fabric_output"
    mkdir -p "$docker_output"
    
    # start fabric metrics monitor
    echo "Starting fabric metrics monitoring for $container_name (ID: $container_id, Port: $metrics_port)"
    "$SCRIPTS_DIR/fabric_monitor.sh" localhost "$metrics_port" "$metrics_list" "$fabric_output" "$INTERVAL" >> "$LOGS_DIR/fabric_monitor.log" 2>&1 &
    
    # start docker resource monitor
    echo "Starting docker monitoring for $container_name (ID: $container_id)"
    "$SCRIPTS_DIR/docker_monitor.sh" "$container_id" "$docker_output" "$INTERVAL" >> "$LOGS_DIR/docker_monitor.log" 2>&1 &
}

main() {
    echo "Starting monitoring for all Fabric nodes..."
    echo "Using container ports from: $PORTS_FILE"
    
    # get all Fabric node containers
    local containers
    containers=$(get_fabric_containers)
    
    if [ -z "$containers" ]; then
        echo "No Fabric containers found!"
        exit 1
    fi
    
    # start monitor for each node
    while read -r line; do
        local container_id
        local container_name
        container_id=$(echo "$line" | awk '{print $1}')
        container_name=$(echo "$line" | awk '{print $2}')
        
        start_monitoring "$container_id" "$container_name"
    done <<< "$containers"
    
    echo "Monitoring started for all Fabric nodes."
    echo "Use 'ps aux | grep -E \"fabric_monitor.sh|docker_monitor.sh\"' to check running processes."
    echo "Use 'tail -f $LOGS_DIR/fabric_monitor.log' or 'tail -f $LOGS_DIR/docker_monitor.log' to view logs."
}

main