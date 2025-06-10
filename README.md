# foundry-template

A bleeding-edge Foundry project generator for your next smart contract project 🚀

## TL;DR

```bash
pip install cruft
cruft create https://github.com/your-org/foundry-template
```

**OR**

```bash
pip install cookiecutter
cookiecutter https://github.com/your-org/foundry-template
```

## 💥 Features

This is a batteries-included cookiecutter 🍪 template to get you started with the essentials you'll need for your next Solidity project 😉

### Development
- **Foundry toolkit** - Complete development environment with forge, cast, and anvil
- **Automated code formatting** with `forge fmt` and consistent style configuration
- **Smart contract linting** with Solhint, complete with a ready-to-run `.solhint.json` configuration
- **Security analysis** with Slither integration for vulnerability detection
- **Multiple testing strategies** - Unit tests, fuzz testing, and invariant testing examples
- **Easy setup with Makefile** - run tests, linters, security checks, and generate reports with a single command
- **Demo vulnerability contracts** - Learn from intentional vulnerabilities (VulnerableLendingPool) for security education
- **OpenZeppelin integration** - Optional integration with battle-tested smart contract libraries
- **Gas optimization** - Built-in gas reporting and optimization configurations

### Deployment & DevOps
- **GitHub Actions** with predefined workflows including CI/CD, testing, and deployment validation
- **Zeus deployment toolkit** - Optional integration for complex deployment processes (EigenLayer's tool)
- **Automated template updates** with cruft - keep your project in sync with template improvements
- **Security reporting workflow** - Configured vulnerability disclosure process
- **Deployment script validation** - Automatic testing of deployment scripts before production
- **Multi-environment support** - Ready configurations for testnets and mainnet

### Project Structure
- **Organized directory structure** - Clear separation of contracts, tests, scripts, and documentation
- **Comprehensive `.gitignore`** and `.gitattributes` - You won't have to bother with trivialities
- **License templates** - Choose from MIT, Apache 2.0, BSD-3-Clause, GPL-3.0, or UNLICENSED
- **Professional documentation** - README templates, security policies, and contribution guidelines

## 📦 Quick Start

### Option 1: Using Cruft (Recommended)
```bash
pip install cruft
cruft create https://github.com/your-org/foundry-template
```
✅ Supports automatic template updates  
✅ Tracks template version

### Option 2: Using Cookiecutter
```bash
pip install cookiecutter  
cookiecutter https://github.com/your-org/foundry-template
```
✅ Simple and direct  
❌ No template update support

## 🎛️ Input Variables

Cookiecutter will ask you to fill some variables that will be used to generate your project from this template. This section lists all the input variables, their default values, and what they are used for.

**Quick Note:** Cookiecutter needs all inputs to have a default value. These defaults should be filled with actual values during the setup!

| Parameter | Default Value | Usage |
|-----------|---------------|-------|
| `project_name` | "My Foundry Project" | Name of the project. A directory will be created with this name (converted to snake_case) |
| `contact_email` | "" | Email for security reports and project inquiries. Leave empty to exclude security reporting |
| `license` | "MIT" | Choose from MIT, Apache 2.0, BSD-3-Clause, GPL-3.0, or UNLICENSED |
| `use_openzeppelin` | "y" | Include OpenZeppelin contracts library (y/n) |
| `use_openzeppelin_upgradeable` | "y" | Include OpenZeppelin upgradeable contracts (y/n) |
| `use_zeus` | "y" | Include Zeus deployment toolkit (y/n) |
| `zeus_metadata_repo` | "" | GitHub repository for Zeus metadata storage (required if using Zeus) |
| `cleanup_demo` | "y" | Remove demo/example files from template (y/n) |
| `enable_auto_update` | "y" | Enable automatic template updates via GitHub Actions (y/n) |

**Important:** If you enable auto-updates, you'll need to set up a GitHub Personal Access Token named `CICD_DOCKER_BUILD_PAT` in your repository secrets.

## 🛠️ What You Get

After running the template, you'll have a complete Foundry project with:

```
your-project/
├── src/                          # Smart contracts
│   ├── Counter.sol              # Simple example contract
│   ├── CounterV2.sol            # Upgrade example
│   └── VulnerableLendingPool.sol # Educational vulnerability examples
├── test/                         # Comprehensive testing suite
│   ├── unit/                    # Unit tests
│   ├── fuzz/                    # Fuzz testing
│   └── invariant/               # Invariant testing
├── script/                       # Deployment and utility scripts
├── .github/workflows/           # CI/CD automation
├── foundry.toml                 # Foundry configuration
├── remappings.txt              # Import remappings
├── package.json                # Node.js dependencies
└── SECURITY.md                 # Security vulnerability reporting
```

## 🔒 Security Features

- **Vulnerability disclosure process** - Professional security reporting workflow
- **Educational vulnerability examples** - Learn from intentional security flaws
- **Automated security scanning** - Slither integration for vulnerability detection
- **Security best practices** - Pre-configured tools and workflows

## 🚀 Getting Started After Generation

1. **Install dependencies:**
   ```bash
   cd your-project
   yarn install  # Node.js dependencies
   forge build   # Compile contracts
   ```

2. **Run tests:**
   ```bash
   forge test -vvv
   ```

3. **Security analysis:**
   ```bash
   slither src/
   ```

4. **Deploy (example):**
   ```bash
   forge script script/Deploy.s.sol --rpc-url <your_rpc_url> --private-key <your_private_key>
   ```

## 🔄 Template Updates

If you used `cruft create`, you can update your project when the template improves:

```bash
cruft check   # Check for updates
cruft update  # Apply updates
```

## 🥈 Similar Projects

Other similar project(s) that you might want to check out:

- [foundry-template](https://github.com/foundry-rs/foundry-template) - Official Foundry template
- [forge-template](https://github.com/FrankieIsLost/forge-template) - Minimal Forge template
- [foundry-starter-kit](https://github.com/smartcontractkit/foundry-starter-kit) - Chainlink's starter kit
- [solidity-template](https://github.com/paulrberg/solidity-template) - Paul Razvan Berg's template

P.S. If you know of any project similar to foundry-template (that isn't listed here), let me know and I'll be happy to list it 😉

Forks of foundry-template are welcome as well - given they have significant changes compared to upstream!

P.P.S. The emoji for this section fits well :p

## 📄 License

This template is licensed under MIT. The generated projects will use the license you choose during setup.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

---

**Happy smart contract development! 🔥⚡** 