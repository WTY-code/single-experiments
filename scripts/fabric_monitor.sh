#!/bin/bash

# check args number
if [ $# -ne 5 ]; then
    echo "Usage: $0 <node-address> <port> <metrics-list-file> <output-dir> <interval-seconds>"
    echo "Example: $0 localhost 9444 metrics.txt /root/ruc/experiments/metrics 5"
    exit 1
fi

# parse args
NODE_ADDRESS=$1
PORT=$2
METRICS_LIST_FILE=$3
OUTPUT_DIR=$4
INTERVAL=$5

mkdir -p "$OUTPUT_DIR"

# clear current output dir
echo "Cleaning output directory: $OUTPUT_DIR"
find "$OUTPUT_DIR" -mindepth 1 -delete 2>/dev/null

# check metrics.txt
if [ ! -f "$METRICS_LIST_FILE" ]; then
    echo "Metrics list file not found: $METRICS_LIST_FILE"
    exit 1
fi


# load metrcis list
mapfile -t METRICS < "$METRICS_LIST_FILE"

while true; do
    # get timestamp (format: [YYYY-MM-DD HH:MM:SS])
    TIMESTAMP="[$(date +'%Y-%m-%d %H:%M:%S')]"
    
    # scrape all metrics
    ALL_METRICS=$(curl -s "http://$NODE_ADDRESS:$PORT/metrics")
    
    # traverse all metrics
    for METRIC in "${METRICS[@]}"; do
        # skip blank line
        if [[ -z "$METRIC" ]]; then
            continue
        fi
        
        # prepare output file
        OUTPUT_FILE="${OUTPUT_DIR}/${METRIC}.txt"
        
        # filter out metric type and data line
        TYPE_LINE=$(echo "$ALL_METRICS" | grep -m 1 "^# TYPE $METRIC ")
        METRIC_LINES=$(echo "$ALL_METRICS" | grep "^$METRIC")
        
        # if find the metric
        if [[ -n "$TYPE_LINE" ]] || [[ -n "$METRIC_LINES" ]]; then
            # wirte type line
            [[ -n "$TYPE_LINE" ]] && echo "$TYPE_LINE" >> "$OUTPUT_FILE"
            
            # write data line with timestamp
            while IFS= read -r LINE; do
                echo "$TIMESTAMP $LINE" >> "$OUTPUT_FILE"
            done <<< "$METRIC_LINES"
        else
            # record missing metric
            echo "# TYPE $METRIC not_found" >> "$OUTPUT_FILE"
            echo "$TIMESTAMP $METRIC 0" >> "$OUTPUT_FILE"
        fi
    done
    
    sleep "$INTERVAL"
done