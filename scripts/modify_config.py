import sys
from ruamel.yaml import YAML

def load_input(file_path):
    """load input file, dump yaml in python dictonary"""
    updates = {}
    with open(file_path, 'r') as f:
        for line in f:
            line = line.strip()
            if line:  # skip blank line
                parts = line.split(maxsplit=1) 
                if len(parts) == 2:
                    key = parts[0]
                    value = parts[1].strip()
                    updates[key] = value
    return updates

def update_yaml(data, updates):
    """Recursively traverse YAML data and update matching parameters"""
    if isinstance(data, dict):
        for key in list(data.keys()):
            if key in updates:
                # convert according to original data type
                orig_value = data[key]
                
                if isinstance(orig_value, int):
                    try:
                        data[key] = int(updates[key])
                    except ValueError:
                        data[key] = updates[key]  # keep the data as string
                elif isinstance(orig_value, float):
                    try:
                        data[key] = float(updates[key])
                    except ValueError:
                        data[key] = updates[key]  # keep the data as string
                else:
                    data[key] = updates[key]  # keep the data as string or its primitive type
                
                del updates[key]  # remove parameters processed
            else:
                # recursively process children nodes in dict
                update_yaml(data[key], updates)
                
    elif isinstance(data, list):
        for item in data:
            update_yaml(item, updates)

def main(yaml_file, input_file):
    # load input files
    updates = load_input(input_file)
    if not updates:
        print("ERROR: Can not find legal parameters!")
        return
    
    # laod yaml
    yaml = YAML()
    yaml.preserve_quotes = True  # preserve quote in yaml
    yaml.width = 120  # Prevent long lines from wrapping
    
    with open(yaml_file, 'r') as f:
        data = yaml.load(f)
    
    # back up number of parameters in input
    original_count = len(updates)
    
    # update yaml
    update_yaml(data, updates)
    
    # check if any parameters not be modified
    if updates:
        print(f"WARNING: Can't find parameters: {', '.join(updates.keys())}")
    else:
        print(f"SUCCESS: Modified {original_count} parameters")
    
    # write back to yaml
    with open(yaml_file, 'w') as f:
        yaml.dump(data, f)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("usage: python3 modify_config.py <configtx.yaml> <parameters_to_modify.txt>")
        sys.exit(1)
    
    yaml_file = sys.argv[1]
    input_file = sys.argv[2]
    main(yaml_file, input_file)