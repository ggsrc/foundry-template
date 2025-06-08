#!/usr/bin/env python
"""Post-generation hook for Foundry template."""

import os
import shutil
import json
import subprocess

def remove_file(filepath):
    """Remove file if it exists."""
    if os.path.exists(filepath):
        os.remove(filepath)

def remove_dir(dirpath):
    """Remove directory if it exists."""
    if os.path.exists(dirpath):
        shutil.rmtree(dirpath)

def remove_from_remapping(pattern):
    """Remove lines containing pattern from remappings.txt."""
    remapping_file = 'remappings.txt'
    if os.path.exists(remapping_file):
        with open(remapping_file, 'r') as f:
            lines = f.readlines()
        
        filtered_lines = [line for line in lines if pattern not in line]
        
        with open(remapping_file, 'w') as f:
            f.writelines(filtered_lines)

def remove_from_package_json(package_name):
    """Remove package dependency from package.json."""
    package_file = 'package.json'
    if os.path.exists(package_file):
        with open(package_file, 'r') as f:
            package_data = json.load(f)
        
        if 'dependencies' in package_data and package_name in package_data['dependencies']:
            del package_data['dependencies'][package_name]
        
        if 'devDependencies' in package_data and package_name in package_data['devDependencies']:
            del package_data['devDependencies'][package_name]
        
        with open(package_file, 'w') as f:
            json.dump(package_data, f, indent=2)

def remove_from_yarn_lock(package_name):
    """Remove package dependencies from yarn.lock."""
    yarn_lock_file = 'yarn.lock'
    if os.path.exists(yarn_lock_file):
        with open(yarn_lock_file, 'r') as f:
            content = f.read()
        
        lines = content.split('\n')
        filtered_lines = []
        skip_block = False
        
        for line in lines:
            if package_name in line and (line.startswith('"') or line.startswith(package_name)):
                skip_block = True
                continue
            elif skip_block and line.strip() == '':
                skip_block = False
                continue
            elif skip_block:
                continue
            else:
                filtered_lines.append(line)
        
        with open(yarn_lock_file, 'w') as f:
            f.write('\n'.join(filtered_lines))

def remove_from_env_example(env_var):
    """Remove environment variable line from .env.example."""
    env_file = '.env.example'
    if os.path.exists(env_file):
        with open(env_file, 'r') as f:
            lines = f.readlines()
        
        filtered_lines = [line for line in lines if not line.startswith(f'{env_var}=')]
        
        with open(env_file, 'w') as f:
            f.writelines(filtered_lines)

def handle_license():
    """Handle license file based on user choice."""
    if '{{cookiecutter.license}}' == 'None':
        remove_file('LICENSE')

def handle_zeus_cleanup():
    """Handle zeus-related cleanup if user chose not to use zeus."""
    if '{{cookiecutter.use_zeus}}' == 'n':
        remove_from_remapping('@zeus-templates/')
        remove_from_package_json('zeus-templates')
        remove_from_yarn_lock('zeus-templates')
        remove_file('.zeus')
        remove_dir('script/releases')
        remove_from_env_example('ZEUS_ENV_DEPLOYER')
        print("Zeus cleanup completed")

def handle_openzeppelin():
    """Handle OpenZeppelin dependencies."""
    if '{{cookiecutter.use_openzeppelin}}' == 'n':
        remove_from_remapping('@openzeppelin/')
        remove_from_package_json('@openzeppelin/contracts')
        remove_from_yarn_lock('@openzeppelin/contracts')
        print("OpenZeppelin cleanup completed")

def handle_openzeppelin_upgradeable():
    """Handle OpenZeppelin upgradeable dependencies."""
    if '{{cookiecutter.use_openzeppelin_upgradeable}}' == 'n':
        remove_from_remapping('@openzeppelin-upgrades/')
        remove_from_package_json('@openzeppelin/contracts-upgradeable')
        remove_from_yarn_lock('@openzeppelin/contracts-upgradeable')
        print("OpenZeppelin upgradeable cleanup completed")

def handle_demo_cleanup():
    """Clean up demo files if requested using existing script."""
    if '{{cookiecutter.cleanup_demo}}' == 'y':
        cleanup_script = 'script/cleanup-demo.sh'
        if os.path.exists(cleanup_script):
            try:
                # Make script executable
                os.chmod(cleanup_script, 0o755)
                # Run the cleanup script
                subprocess.run(['./script/cleanup-demo.sh'], check=True, capture_output=True, text=True)
                print("Demo cleanup completed")
            except subprocess.CalledProcessError as e:
                print(f"Demo cleanup failed: {e}")
        else:
            print("Cleanup script not found, skipping demo cleanup")

def main():
    """Main post-generation logic."""
    # Handle license
    handle_license()
    
    # Handle Zeus cleanup
    handle_zeus_cleanup()
    
    # Handle OpenZeppelin
    handle_openzeppelin()
    
    # Handle OpenZeppelin upgradeable
    handle_openzeppelin_upgradeable()
    
    # Handle demo cleanup
    handle_demo_cleanup()
    
    print(f"Project '{{cookiecutter.project_name}}' created successfully!")

if __name__ == '__main__':
    main()