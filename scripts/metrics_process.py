import os
import csv
import shutil
from datetime import datetime
from collections import defaultdict

# Get current timestamp for directory naming
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
base_dir = "/root/ruc/experiments/metrics"
output_dir = os.path.join(base_dir, timestamp)
backup_dir = os.path.join(output_dir, "backup")
lists_dir = "/root/ruc/experiments//config"
os.makedirs(backup_dir, exist_ok=True)

# Process Docker metrics
def process_docker_metrics():
    docker_dir = os.path.join(base_dir, "docker")
    metrics = [
        "cpu_percentage",
        "mem_percentage",
        "disk_read_rate",
        "disk_write_rate",
        "net_rx_rate",
        "net_tx_rate"
    ]
    
    # Initialize data structures
    data = {metric: defaultdict(dict) for metric in metrics}
    all_nodes = []
    
    # Read all docker CSV files
    for node_dir in os.listdir(docker_dir):
        node_path = os.path.join(docker_dir, node_dir)
        if os.path.isdir(node_path):
            csv_file = os.path.join(node_path, "docker_monitor.csv")
            if os.path.exists(csv_file):
                all_nodes.append(node_dir)
                with open(csv_file, 'r') as f:
                    reader = csv.DictReader(f)
                    for row in reader:
                        timestamp = row['timestamp']
                        for metric in metrics:
                            data[metric][timestamp][node_dir] = row[metric]
    
    # Write output files
    for metric in metrics:
        output_file = os.path.join(os.path.join(output_dir, "docker"), f"{metric}.csv")
        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        # output_file = os.path.join(output_dir, f"{metric}.csv")
        with open(output_file, 'w', newline='') as f:
            writer = csv.writer(f)
            # Write header
            writer.writerow(['timestamp'] + sorted(all_nodes))
            
            # Write data rows
            for timestamp in sorted(data[metric].keys()):
                row = [timestamp]
                for node in sorted(all_nodes):
                    row.append(data[metric][timestamp].get(node, ''))
                writer.writerow(row)
    
    # Move original docker directory to backup
    shutil.move(docker_dir, os.path.join(backup_dir, "docker"))

# Process Fabric metrics
def process_fabric_metrics():
    fabric_dir = os.path.join(base_dir, "fabric")
    # lists_dir = os.path.join(base_dir, "lists")
    
    # Read node lists
    with open(os.path.join(lists_dir, "fabric_merge_orderer.txt"), 'r') as f:
        orderer_metrics = [line.strip() for line in f if line.strip()]
    
    with open(os.path.join(lists_dir, "fabric_merge_peer.txt"), 'r') as f:
        peer_metrics = [line.strip() for line in f if line.strip()]
    
    # Initialize data structures
    orderer_data = defaultdict(lambda: defaultdict(dict))
    peer_data = defaultdict(lambda: defaultdict(dict))
    
    # Find all orderer and peer nodes
    orderer_nodes = []
    peer_nodes = []
    
    for node_dir in os.listdir(fabric_dir):
        node_path = os.path.join(fabric_dir, node_dir)
        if os.path.isdir(node_path):
            if node_dir.startswith("orderer"):
                orderer_nodes.append(node_dir)
            elif node_dir.startswith("peer"):
                peer_nodes.append(node_dir)
    
    # Process orderer metrics
    for metric in orderer_metrics:
        for node in orderer_nodes:
            metric_file = os.path.join(fabric_dir, node, f"{metric}.txt")
            if os.path.exists(metric_file):
                with open(metric_file, 'r') as f:
                    lines = f.readlines()
                    for line in lines:
                        if line.startswith('['):
                            # Parse timestamp and value
                            parts = line.split(']')
                            timestamp = parts[0][1:].strip()
                            value = parts[1].strip().split()[-1]
                            orderer_data[metric][timestamp][node] = value
    
    # Process peer metrics
    for metric in peer_metrics:
        for node in peer_nodes:
            metric_file = os.path.join(fabric_dir, node, f"{metric}.txt")
            if os.path.exists(metric_file):
                with open(metric_file, 'r') as f:
                    lines = f.readlines()
                    for line in lines:
                        if line.startswith('['):
                            # Parse timestamp and value
                            parts = line.split(']')
                            timestamp = parts[0][1:].strip()
                            value = parts[1].strip().split()[-1]
                            peer_data[metric][timestamp][node] = value
    
    # Create output directory for fabric metrics
    fabric_output_dir = os.path.join(output_dir, "fabric")
    os.makedirs(fabric_output_dir, exist_ok=True)
    
    # Write orderer metrics
    for metric, metric_data in orderer_data.items():
        output_file = os.path.join(fabric_output_dir, f"{metric}.csv")
        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        with open(output_file, 'w', newline='') as f:
            writer = csv.writer(f)
            # Write header
            writer.writerow(['timestamp'] + sorted(orderer_nodes))
            
            # Write data rows
            for timestamp in sorted(metric_data.keys()):
                row = [timestamp]
                for node in sorted(orderer_nodes):
                    row.append(metric_data[timestamp].get(node, ''))
                writer.writerow(row)
    
    # Write peer metrics
    for metric, metric_data in peer_data.items():
        output_file = os.path.join(fabric_output_dir, f"{metric}.csv")
        with open(output_file, 'w', newline='') as f:
            writer = csv.writer(f)
            # Write header
            writer.writerow(['timestamp'] + sorted(peer_nodes))
            
            # Write data rows
            for timestamp in sorted(metric_data.keys()):
                row = [timestamp]
                for node in sorted(peer_nodes):
                    row.append(metric_data[timestamp].get(node, ''))
                writer.writerow(row)
    
    # Move original fabric directory to backup
    shutil.move(fabric_dir, os.path.join(backup_dir, "fabric"))

# Main execution
if __name__ == "__main__":
    process_docker_metrics()
    process_fabric_metrics()
    print(f"Processing complete. Output saved to {output_dir}")