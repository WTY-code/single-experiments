#!/bin/bash

EXPERIMENT_HOME="/root/ruc/experiments"
LOGS_DIR="$EXPERIMENT_HOME/logs"
SCRIPTS_DIR="$EXPERIMENT_HOME/scripts"

stop_monitoring() {
    echo "Stopping all monitoring processes..."
    
    # stop docker_monitor.sh process
    pids=$(pgrep -f "docker_monitor.sh")
    if [ -n "$pids" ]; then
        echo "Found docker_monitor processes: $pids"
        kill -9 $pids
    else
        echo "No running docker_monitor processes found"
    fi
    
    # stop fabric_monitor.sh process
    pids=$(pgrep -f "fabric_monitor.sh")
    if [ -n "$pids" ]; then
        echo "Found fabric_monitor processes: $pids"
        kill -9 $pids
    else
        echo "No running fabric_monitor processes found"
    fi
    
    # check if stop processed successfully
    if pgrep -f "monitor.sh" >/dev/null; then
        echo "Warning: Some monitoring processes still running"
    else
        echo "All monitoring processes stopped successfully"
    fi
}

clean_logs() {
    echo "Cleaning up log files..."
    find "$LOGS_DIR" -type f -name "*.log" -exec truncate -s 0 {} \;
    echo "Log files cleaned"
}

main() {
    stop_monitoring
    # clean_logs
}

main