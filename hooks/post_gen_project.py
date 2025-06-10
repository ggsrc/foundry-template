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
        remove_file('.github/workflows/validate-deployment-scripts.yml')
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

def handle_tenderly_cleanup():
    """Handle Tenderly-related cleanup if user chose not to use Tenderly."""
    if '{{cookiecutter.use_tenderly}}' == 'n':
        remove_file('src/SimpleToken.sol')
        remove_file('script/deploy/SimpleToken.s.sol')
        remove_dir('fixtures')
        remove_file('docs/TENDERLY.md')
        remove_file('.github/workflows/tenderly-ci-cd.yml')
        print("Tenderly cleanup completed")

def handle_demo_cleanup():
    """Clean up demo files if requested using existing script."""
    if '{{cookiecutter.cleanup_demo}}' == 'y':
        cleanup_script = 'script/cleanup-demo.sh'
        test_readme = 'test/README.md'
        
        if os.path.exists(cleanup_script):
            try:
                # Backup test/README.md if it exists
                test_readme_backup = None
                if os.path.exists(test_readme):
                    test_readme_backup = '/tmp/test_readme_backup.md'
                    shutil.copy2(test_readme, test_readme_backup)
                    print("Backed up test/README.md")
                
                # Make script executable
                os.chmod(cleanup_script, 0o755)
                
                # Run the cleanup script
                subprocess.run(['./script/cleanup-demo.sh'], check=True, capture_output=True, text=True)
                
                # Restore test/README.md if it was backed up
                if test_readme_backup and os.path.exists(test_readme_backup):
                    shutil.copy2(test_readme_backup, test_readme)
                    os.remove(test_readme_backup)
                    print("Restored test/README.md")
                
                print("Demo cleanup completed")
            except subprocess.CalledProcessError as e:
                print(f"Demo cleanup failed: {e}")
        else:
            print("Cleanup script not found, skipping demo cleanup")

def install_dependencies():
    """Install dependencies using yarn."""
    if os.path.exists('package.json'):
        try:
            print("Installing dependencies with yarn...")
            result = subprocess.run(['yarn', 'install'], check=True, capture_output=True, text=True)
            print("Dependencies installed successfully!")
        except subprocess.CalledProcessError as e:
            print(f"Failed to install dependencies: {e}")
            print("You can manually run 'yarn install' later")
        except FileNotFoundError:
            print("Yarn not found. Please install yarn or run 'npm install' manually")
    else:
        print("No package.json found, skipping dependency installation")

def git_init():
    """Initialize git repository."""
    try:
        # Check if already a git repository
        if os.path.exists('.git'):
            print("Git repository already exists, skipping git init")
            return
        
        print("Initializing git repository...")
        subprocess.run(['git', 'init'], check=True, capture_output=True, text=True)
        print("Git repository initialized successfully!")
    except subprocess.CalledProcessError as e:
        print(f"Failed to initialize git repository: {e}")
        print("You can manually run 'git init' later")
    except FileNotFoundError:
        print("Git not found. Please install git or initialize repository manually")

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
    
    # Handle Tenderly cleanup
    handle_tenderly_cleanup()
    
    # Handle demo cleanup
    handle_demo_cleanup()
    
    # Install dependencies
    install_dependencies()
    
    # Initialize git repository
    git_init()
    
    print(f"Project '{{cookiecutter.project_name}}' created successfully!")
    
    # Print next steps
    print("\n" + "="*60)
    print("🎉 PROJECT SETUP COMPLETE!")
    print("="*60)
    print("\n📋 NEXT STEPS:")
    print("1. Build and test your project:")
    print("   forge build")
    print('   forge test --no-match-path "script/**"')
    print("\n2. If everything works correctly, initialize git:")
    print("   git add .")
    print("   git commit -m 'Initial commit'")
    print("   git push")
    print("\n3. Explore available commands:")
    print("   make help")
    print("\nSECURITY TOOLS:")
    print("   make audit     # Run all security tools")
    print("   make slither   # Static analysis")
    print("   make mythril   # Symbolic execution")
    print("   make 4naly3er  # Audit report")
    print("   make aderyn    # Modern static analysis")
    print("\nFor more information, check the README.md file!")
    print("="*60)

if __name__ == '__main__':
    main()