# Foundry Template

A Foundry project generator for your next smart contract project 🚀

## Getting Started

### Requirements

Please install the following:

- **Git**
  - You'll know you've done it right if you can run `git --version`
- **Foundry / Foundryup**
  - You can test you've installed them right by running `forge --version` and get an output like: `forge 0.3.0 (f016135 2022-07-04T00:15:02.930499Z)`
  - To get the latest of each, just run `foundryup`
- **Cruft** (Project Template Tool)
  - **macOS**: `brew install cruft` 
  - **Other platforms**: `pip install cruft`
- **Make** (Build Tool)
  - Usually pre-installed on macOS/Linux
  - **Windows**: Install via [chocolatey](https://chocolatey.org/): `choco install make`

### Quickstart

```bash
# Install cruft (if you haven't already)
# macOS:
brew install cruft
# Other platforms:
pip install cruft

# Create a new project from the template
cruft create https://github.com/ggsrc/foundry-template

# Navigate to your new project directory
cd your-project-name

# Build the contracts
forge build
```

# Modules

## Module 1: Testing

We've specially designed a vulnerable contract in `{{cookiecutter.project_slug}}/src/VulnerableLendingPool.sol` for educational purposes. This contract contains intentional vulnerabilities that are revealed through different testing strategies:

- **Unit Tests** (`test/unit/`) - Test individual functions and reveal basic logic flaws
- **Fuzz Tests** (`test/fuzz/`) - Use random inputs to discover edge cases and input validation issues  
- **Invariant Tests** (`test/invariant/`) - Test system-wide properties to uncover complex vulnerabilities like reentrancy and state inconsistencies

Each testing approach exposes different types of vulnerabilities in the contract, making it an excellent learning resource for smart contract security.

**For detailed vulnerability analysis and testing strategies, see:**
👉 [Testing Strategy & Vulnerability Analysis]({{cookiecutter.project_slug}}/test/README.md)

## Module 2: Deployment

The template supports two deployment strategies:

### Native Forge Deployment
If you choose not to use Zeus during template creation, you can deploy contracts using Foundry's native methods:

```bash
forge script script/Deploy.s.sol --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast
```

For more information, consult the [Foundry Book](https://book.getfoundry.sh/).

### Zeus Deployment
If you selected Zeus during template creation, you get access to advanced deployment features:

- **Complex deployment orchestration** with dependency management
- **Deployment metadata tracking** for better project management
- **Multi-environment support** with consistent deployment patterns
- **Upgrade management** for proxy contracts

See the [Deployment Guide]({{cookiecutter.project_slug}}/script/releases/README.md) for detailed Zeus usage instructions.

## Module 3: Security

The template includes two static analysis tools for comprehensive security auditing:

### Slither
**Slither** is Trail of Bits' static analysis framework for Solidity.

**Installation**: If not already installed, visit the [official Slither repository](https://github.com/crytic/slither) for installation instructions.

**Usage**:
```bash
make slither
```

### 4naly3er
**4naly3er** is another static audit tool that provides complementary analysis.

**Usage**:
```bash
make 4naly3er
```

This will generate a comprehensive audit report in the `audit/` folder, providing detailed analysis of potential vulnerabilities and code quality issues.

## Module 4: Linting

The template includes automated code quality tools to maintain consistent code style and catch common issues:

### Solidity Linting
**Solhint** is integrated for Solidity code style and quality checking.

**Usage**:
```bash
make lint      # Check for linting issues
make lint-fix  # Automatically fix linting issues where possible
```

The linting rules are configured in `.solhint.json` and help enforce:
- **Code style consistency** - Consistent formatting and naming conventions
- **Best practices** - Common Solidity patterns and anti-patterns
- **Gas optimization hints** - Suggestions for gas-efficient code
- **Security patterns** - Basic security-related code patterns

## Module 5: Demo Files

The template comes with educational demo files to help you understand smart contract development patterns:

### Included Demo Files
- **`src/Counter.sol`** - Simple counter contract demonstrating basic state management
- **`src/CounterV2.sol`** - Upgraded version showing contract upgrade patterns
- **`src/VulnerableLendingPool.sol`** - Educational contract with intentional vulnerabilities
- **Sample test files** - Testing examples for all demo contracts
- **Deployment scripts** - Zeus deployment examples

### Managing Demo Files
You can easily remove all demo files when you're ready to start your own project:

```bash
make cleanup-demo
```

This command will:
- Remove all demo files
- Keep the project structure intact for your own contracts

**Note**: You can also choose to exclude demo files during template creation by answering "y" to the `cleanup_demo` prompt.

## Module 6: GitHub Workflows

The template includes several pre-configured GitHub Actions workflows located in `{{cookiecutter.project_slug}}/.github/workflows/`:

### Core Workflows
- **`test-template.yml`** - Runs comprehensive testing on every commit
- **`ci.yml`** - Continuous integration for contract compilation and testing

### Conditional Workflows
- **`cruft-update.yml`** - Automatic template updates (only included if auto-update is enabled during template creation)
- **`validate-deployment-scripts.yml`** - Validates Zeus deployment scripts (only included if Zeus is selected during template creation)

These workflows provide automated testing, security scanning, and deployment validation to ensure code quality and reliability throughout the development process.

# Contributing

Contributions are always welcome! Open a PR or an issue! If you do contribute please add `"solidity.formatter": "forge"` to your VSCode Settings, or run `forge fmt` before you commit and push.