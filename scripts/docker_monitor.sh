#!/bin/bash

# check args
if [ $# -ne 3 ]; then
    echo "Usage: $0 <container-id> <log-file-path> <interval>"
    exit 1
fi

CONTAINER_ID="$1"
OUTPUT_DIR="$2"
INTERVAL="$3"

# check jq
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install jq first."
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
OUTPUT_FILE="${OUTPUT_DIR}/docker_monitor.csv"

# initialization
prev_cpu_total=0
prev_system_cpu=0
prev_disk_write=0
prev_disk_read=0
prev_rx_bytes=0
prev_tx_bytes=0
prev_timestamp=0

# write csv head
echo "timestamp,cpu_percentage,mem_usage,mem_percentage,disk_read_rate,disk_write_rate,net_rx_rate,net_rx_dropped,net_tx_rate,net_tx_dropped" > $OUTPUT_FILE

# main loop
while :; do
    # require docker metrics
    stats=$(curl -s --unix-socket /var/run/docker.sock "http://localhost/containers/$CONTAINER_ID/stats?stream=false")
    
    # extract specific metrics
    current_timestamp=$(echo "$stats" | jq -r '.read')
    cpu_total=$(echo "$stats" | jq -r '.cpu_stats.cpu_usage.total_usage')
    system_cpu=$(echo "$stats" | jq -r '.cpu_stats.system_cpu_usage')
    disk_read=$(echo "$stats" | jq -r '.blkio_stats.io_service_bytes_recursive | map(select(.op=="read").value) | add')
    disk_write=$(echo "$stats" | jq -r '.blkio_stats.io_service_bytes_recursive | map(select(.op=="write").value) | add')
    mem_usage=$(echo "$stats" | jq -r '.memory_stats.usage')
    mem_limit=$(echo "$stats" | jq -r '.memory_stats.limit')
    rx_bytes=$(echo "$stats" | jq -r '.networks.eth0.rx_bytes')
    rx_dropped=$(echo "$stats" | jq -r '.networks.eth0.rx_dropped')
    tx_bytes=$(echo "$stats" | jq -r '.networks.eth0.tx_bytes')
    tx_dropped=$(echo "$stats" | jq -r '.networks.eth0.tx_dropped')

    # calculate CPU usage
    if [ $prev_cpu_total -ne 0 ] && [ $prev_system_cpu -ne 0 ]; then
        cpu_diff=$((cpu_total - prev_cpu_total))
        system_diff=$((system_cpu - prev_system_cpu))
        
        if [ $system_diff -gt 0 ]; then
            cpu_percentage=$(echo "scale=2; $cpu_diff * 100 / $system_diff" | bc)
        else
            cpu_percentage=0.00
        fi
    else
        cpu_percentage=0.00
    fi

    # calculate memory usage
    if [ $mem_limit -gt 0 ]; then
        mem_percentage=$(echo "scale=2; $mem_usage * 100 / $mem_limit" | bc)
    else
        mem_percentage=0.00
    fi

    # calculate disk I/O (KB/s)
    if [ $prev_disk_write -ne 0 ] && [ $prev_timestamp != "0" ]; then
        disk_read_diff=$((disk_read - prev_disk_read))
        disk_write_diff=$((disk_write - prev_disk_write))
        time_diff=$(date -d "$current_timestamp" +%s.%N | awk -v prev="$prev_timestamp" '{ print $0 - prev }')
        
        if (( $(echo "$time_diff > 0" | bc -l) )); then
            disk_read_rate=$(echo "scale=2; $disk_read_diff / $time_diff / 1024" | bc)
            disk_write_rate=$(echo "scale=2; $disk_write_diff / $time_diff / 1024" | bc)
        else
            disk_read_rate=0.00
            disk_write_rate=0.00
        fi
    else
        disk_read_rate=0.00
        disk_write_rate=0.00
    fi

    # calculate network I/O (KB/s)
    if [ $prev_rx_bytes -ne 0 ] && [ $prev_timestamp != "0" ]; then
        rx_diff=$((rx_bytes - prev_rx_bytes))
        tx_diff=$((tx_bytes - prev_tx_bytes))
        time_diff=$(date -d "$current_timestamp" +%s.%N | awk -v prev="$prev_timestamp" '{ print $0 - prev }')
        
        if (( $(echo "$time_diff > 0" | bc -l) )); then
            rx_rate=$(echo "scale=2; $rx_diff / $time_diff / 1024" | bc)
            tx_rate=$(echo "scale=2; $tx_diff / $time_diff / 1024" | bc)
        else
            rx_rate=0.00
            tx_rate=0.00
        fi
    else
        rx_rate=0.00
        tx_rate=0.00
    fi

    # convert timestamp to readable format 
    log_timestamp=$(date -d "$current_timestamp" "+%Y-%m-%d %H:%M:%S")

    # write into log file
    echo "$log_timestamp,$cpu_percentage,$mem_usage,$mem_percentage,$disk_read_rate,$disk_write_rate,$rx_rate,$rx_dropped,$tx_rate,$tx_dropped" >> $OUTPUT_FILE
    
    # update previous value
    prev_cpu_total=$cpu_total
    prev_system_cpu=$system_cpu
    prev_disk_read=$disk_read
    prev_disk_write=$disk_write
    prev_rx_bytes=$rx_bytes
    prev_tx_bytes=$tx_bytes
    prev_timestamp=$(date -d "$current_timestamp" +%s.%N)
    
    sleep $INTERVAL
done