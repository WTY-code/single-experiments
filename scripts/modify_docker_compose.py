import sys
import ruamel.yaml
import re

def print_modification_info(param_name, param_value, service_name):
    """格式化打印修改信息"""
    print(f"  - 修改服务 '{service_name}' 中的环境变量 '{param_name}' = {param_value}")

def modify_docker_compose(yaml_path, param_path):
    print(f"\n开始修改 Docker Compose 文件: {yaml_path}")
    print(f"使用参数配置文件: {param_path}")
    
    # 读取参数文件并构建参数字典
    param_dict = {}
    total_params = 0
    with open(param_path, 'r') as f:
        # print("\n🔄 读取以下待修改参数: ")
        for line in f:
            line = line.strip()
            if not line:
                continue
            if line.startswith('#'):  # 跳过注释行
                # print(f"    # {line[1:].strip()}")
                continue
                
            parts = line.split(maxsplit=1)
            if len(parts) < 2:
                # print(f"⚠️ 跳过格式错误的行: {line}")
                continue
                
            param_name = parts[0]
            param_value = parts[1].strip()
            param_dict[param_name] = param_value
            total_params += 1
            # print(f"    {param_name} = {param_value}")
    
    print(f"\n共找到 {total_params} 个有效环境变量参数")
    
    # 加载YAML文件
    yaml = ruamel.yaml.YAML()
    yaml.preserve_quotes = True
    
    with open(yaml_path, 'r') as f:
        data = yaml.load(f)
    
    total_modifications = 0
    modified_services = set()
    
    # print("\n🛠️ 开始处理服务:")
    # 遍历所有服务
    for service_name, service_config in data['services'].items():
        if 'environment' not in service_config:
            continue
            
        service_modifications = 0
        # 处理环境变量列表
        new_env = []
        
        for item in service_config['environment']:
            # 跳过注释行
            if isinstance(item, str) and item.strip().startswith('#'):
                new_env.append(item)
                continue
                
            # 解析键值对
            if isinstance(item, str) and '=' in item:
                key, current_value = item.split('=', 1)
                key = key.strip()
                
                # 如果键在参数字典中则更新值
                if key in param_dict:
                    new_value = param_dict[key]
                    new_env.append(f"{key}={new_value}")
                    print_modification_info(key, new_value, service_name)
                    total_modifications += 1
                    service_modifications += 1
                    modified_services.add(service_name)
                else:
                    new_env.append(item)
            else:
                new_env.append(item)
        
        # 更新环境变量列表
        if service_modifications > 0:
            service_config['environment'] = new_env
    
    # 保存修改后的YAML
    with open(yaml_path, 'w') as f:
        yaml.dump(data, f)
    
    # print("\n✅ 修改完成!")
    print(f"共修改了 {total_modifications} 个环境变量条目")
    # print(f"受影响的服务 ({len(modified_services)} 个): {', '.join(modified_services)}")
    # print(f"文件已保存: {yaml_path}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 modify_docker_compose.py <yaml-file> <param-file>")
        # print("Example: python3 modify_docker_compose.py docker-compose.yaml parameters.txt")
        sys.exit(1)
        
    yaml_file = sys.argv[1]
    param_file = sys.argv[2]
    
    try:
        modify_docker_compose(yaml_file, param_file)
    except Exception as e:
        print(f"\nERROR: {str(e)}")
        sys.exit(1)
