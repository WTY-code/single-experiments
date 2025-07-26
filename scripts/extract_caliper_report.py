import os
import csv
import re

def extract_data_from_log(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
        
        # match data line in log
        pattern = r'\| Create a car\. \|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+\.\d+)\s*\|\s*(\d+\.\d+)\s*\|\s*(\d+\.\d+)\s*\|\s*(\d+\.\d+)\s*\|\s*(\d+\.\d+)\s*\|'
        match = re.search(pattern, content)
        
        if match:
            return {
                'Succ': match.group(1),
                'Fail': match.group(2),
                'Send Rate (TPS)': match.group(3),
                'Max Latency (s)': match.group(4),
                'Min Latency (s)': match.group(5),
                'Avg Latency (s)': match.group(6),
                'Throughput (TPS)': match.group(7)
            }
        
        print(f"Warning: Could not extract data from {file_path}")
        print("Last attempt with pattern:", pattern)
        print("Content sample around expected match:")
        # print for debug
        table_start = content.find('+---------------+------+------+')
        if table_start != -1:
            print(content[table_start:table_start+500])
        else:
            print(content[:500])
        return None

def process_directory(root_dir):
    results = []
    
    for dir_name in sorted(os.listdir(root_dir)):
        dir_path = os.path.join(root_dir, dir_name)
        
        if os.path.isdir(dir_path) and not dir_name.startswith(('.', '_')):
            log_file = os.path.join(dir_path, 'summary_table.log')
            if os.path.exists(log_file):
                print(f"Processing: {dir_name}")
                data = extract_data_from_log(log_file)
                if data:
                    data['source'] = dir_name
                    results.append(data)
                else:
                    print(f"Failed to extract data from {dir_name}")
    
    return results

def save_to_csv(data, output_file):
    if not data:
        print("No data to save.")
        return
    
    fieldnames = ['source', 'Succ', 'Fail', 'Send Rate (TPS)', 'Max Latency (s)', 
                  'Min Latency (s)', 'Avg Latency (s)', 'Throughput (TPS)']
    
    with open(output_file, 'w', newline='') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(data)
    print(f"Successfully saved {len(data)} records to {output_file}")

if __name__ == "__main__":
    # set metrics parent dir and output dir
    root_directory = "/root/ruc/experiments/metrics"
    output_csv = "caliper_reports.csv"
    
    print(f"Starting to process directories under {root_directory}")
    all_results = process_directory(root_directory)
    save_to_csv(all_results, output_csv)
    
    print(f"Data extracted and saved to {output_csv}")
    print(f"Total records processed: {len(all_results)}")