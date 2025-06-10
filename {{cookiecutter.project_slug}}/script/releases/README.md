# Zeus Deployment Guide

[Zeus](https://layr-labs.github.io/zeus/) is a tool for managing complex deploy processes for onchain software. This guide covers how to use Zeus with this Foundry template for smart contract deployment and upgrades.

## Prerequisites

### 1. Install Zeus

```bash
npm install -g @layr-labs/zeus
```

### 2. Login to Zeus

```bash
zeus login
```

### 3. Environment Variables Setup

Create a `.env` file in your project root or export environment variables:

```bash
# Deployer address (42-character Ethereum address)
export ZEUS_ENV_DEPLOYER=0x1234567890123456789012345678901234567890

# Environment type
export ENVIRONMENT_TYPE="development"  # or "staging", "production"

# RPC URLs
export RPC_SEPOLIA=https://sepolia.infura.io/v3/YOUR_PROJECT_ID

# Private key for deployment
export DEPLOYER_PRIVATE_KEY=0x...

# Etherscan API Key for contract verification
export ETHERSCAN_API_KEY=your_etherscan_api_key
```

## Project Initialization

### 1. Setup Zeus Permissions

Visit [Zeus Deployer App](https://github.com/apps/zeus-deployer) and install it to your organization and metadata repository.

### 2. Initialize Zeus in Contract Repository

```bash
zeus init
```

During `zeus init`, you'll be prompted to provide your metadata repository URL. This separate repository will store all environment configurations and deployment records.

**After initialization, the project generates:**
- `.zeus` configuration file
- `script/releases/` directory structure

## Environment Management

### 1. Create New Environment

```bash
zeus env new
```

You'll be prompted to enter:
- **Environment name**: e.g., `testnet-sepolia`, `mainnet`, `staging`
- **Version**: usually starts with `0.0.0`
- **Network**: e.g., `Sepolia`, `Ethereum Mainnet`

**Example:**
```bash
✔ Environment name? testnet-sepolia
✔ Chain? Sepolia
+ created environment
```

### 2. View Environment Configuration

```bash
zeus env show testnet-sepolia
```

**Example output:**
```
Environment Parameters
┌──────────────────┬───────────────────┐
│ (index)          │ Values            │
├──────────────────┼───────────────────┤
│ ZEUS_ENV         │ 'testnet-sepolia' │
│ ZEUS_ENV_COMMIT  │ ''                │
│ ZEUS_TEST        │ 'false'           │
│ ZEUS_ENV_VERSION │ '0.0.0'           │
│ ZEUS_VERSION     │ '1.5.2'           │
└──────────────────┴───────────────────┘
```

### 3. Environment File Structure

After creation, environments are stored in the metadata repository:

```
metadata-repo/
  environments/
    mainnet.json       # Production environment
    sepolia.json       # Test environment  
    staging.json       # Staging environment
```

## Writing Deployment Scripts

### 1. Initial Deployment Script

See the initial deployment example at [`script/releases/v1.0.0-initial/1-deploy.s.sol`](script/releases/v1.0.0-initial/1-deploy.s.sol).

This script demonstrates:
- Deploying implementation contracts
- Setting up proxy contracts
- Configuring environment variables
- Including test functions for validation

### 2. Upgrade Script

See the upgrade example at [`script/releases/v2.0.0-upgrade/1-upgrade.s.sol`](script/releases/v2.0.0-upgrade/1-upgrade.s.sol).

This script shows how to:
- Deploy new implementation contracts
- Upgrade existing proxy contracts
- Validate the upgrade process

### 3. Environment Helper Library

The [`script/releases/Env.sol`](script/releases/Env.sol) library provides utilities for:
- Accessing deployment configuration
- Managing environment variables
- Retrieving deployed contract addresses
- Environment type detection

### 4. Setting Environment Parameters

```solidity
// From the actual deployment script (1-deploy.s.sol):
zUpdate("PROXY_ADMIN", deployedProxyAdmin);
zUpdate("DEPLOYER", msg.sender);
zUpdate("ENVIRONMENT_TYPE", Env.isTestEnvironment() ? "test" : "production");

// Example deployment parameters used in this template:
zUpdate("CHAIN_ID", block.chainid);
zUpdate("deployVersion", "v1.0.0");
zUpdate("executorMultisig", 0x123...);
zUpdate("proxyAdmin", address(proxyAdminContract));
```

### 5. Using Environment Variables in Scripts

```solidity
// From Env.sol - accessing deployed contracts:
Counter counterProxy = Env.proxy.counter();
Counter counterV1 = Env.impl.counterV1Impl();
CounterV2 counterV2 = Env.impl.counterV2Impl();

// Accessing environment variables:
address deployer = Env.deployer();
uint256 chainId = Env.chainId();
string memory version = Env.deployVersion();
address admin = Env.proxyAdmin();

// Environment checks:
bool isTest = Env.isTestEnvironment();
bool isProd = Env.isProductionEnvironment();
```

## Upgrade Manifests (upgrade.json)

Each upgrade directory must contain an `upgrade.json` manifest file that defines the upgrade structure and requirements.

### Basic Structure

```json
{
  "name": "initial-counter-deployment",
  "from": "0.0.0",
  "to": "1.0.0",
  "phases": [
    {
      "type": "eoa",
      "filename": "1-deploy.s.sol"
    }
  ]
}
```

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `name` | string | Unique identifier for this upgrade | `"initial-counter-deployment"` |
| `from` | string | Version requirement before upgrade, supports semantic versioning | `"0.0.0"`, `">=1.0.0 <=1.5.1"` |
| `to` | string | Target version after upgrade | `"1.0.0"`, `"2.0.0"` |
| `phases` | array | Array of deployment phases, executed in order | See phase types below |

### Version Constraint Formats

Zeus supports flexible version constraints:

```json
// Exact version
"from": "1.0.0"

// Version range
"from": ">=1.0.0 <=1.5.1"

// Compatible version prefix
"from": "~1.0.0"  // Allows 1.0.x

// Major version compatibility
"from": "^1.0.0"  // Allows 1.x.x
```

### Deployment Phase Types

Zeus supports multiple deployment phase types:

#### 1. EOA Phase (Externally Owned Account)

For transactions that can be executed by any external account:

```json
{
  "type": "eoa",
  "filename": "1-deploy.s.sol"
}
```

**Use cases:**
- Deploy new contracts
- Call functions that don't require special permissions
- Set initial parameters

#### 2. Multisig Phase

For transactions that require multisig wallet execution:

```json
{
  "type": "multisig",
  "filename": "2-upgrade.s.sol"
}
```

**Use cases:**
- Contract upgrade operations
- Modify critical parameters
- Transfer ownership

#### 3. Script Phase

For executing custom scripts with parameter input support:

```json
{
  "type": "script",
  "filename": "3-setup/start.sh",
  "arguments": [
    {
      "type": "url",
      "passBy": "env",
      "inputType": "text",
      "name": "BEACON_URL",
      "prompt": "Enter an ETH2 Beacon RPC URL"
    }
  ]
}
```

### Common Patterns

**Single-phase deployment (simple contracts):**

```json
{
  "name": "simple-deployment",
  "from": "0.0.0",
  "to": "1.0.0",
  "phases": [
    {
      "type": "eoa",
      "filename": "1-deploy.s.sol"
    }
  ]
}
```

**Multi-phase upgrade (complex systems):**

```json
{
  "name": "complex-upgrade",
  "from": "1.0.0",
  "to": "2.0.0",
  "phases": [
    {
      "type": "eoa",
      "filename": "1-deployNewImpl.s.sol"
    },
    {
      "type": "multisig",
      "filename": "2-queueUpgrade.s.sol"
    },
    {
      "type": "multisig",
      "filename": "3-executeUpgrade.s.sol"
    }
  ]
}
```

## Registering Upgrades

### 1. Register Initial Deployment

```bash
zeus upgrade register
```

**Interactive example:**
```bash
✔ Upgrade directory? v1.0.0-initial
Warning: You are currently on (feat/zeus), while the default branch is origin/main. 
Creating an upgrade from here means that anyone applying in the future will need to 
checkout this non-default branch. Are you sure you want to continue?
✔ Are you sure you want to continue? yes

Creating the following upgrade:
        initial-counter-deployment
                requires: 0.0.0
                upgrades to: 1.0.0
                pinned to commit: feat/zeus@c5b91dc

                Deploy phases:
                        1. 1-deploy.s.sol
✔ Save? yes
+ created upgrade (initial-counter-deployment)
```

### 2. View Available Upgrades

```bash
zeus upgrade list --env testnet-sepolia
```

**Output:**
```
- v1.0.0-initial ('initial-counter-deployment') - (0.0.0) => 1.0.0
```

### 3. Upgrade Manifest Structure

Each upgrade directory contains an `upgrade.json` manifest. See examples:
- [`script/releases/v1.0.0-initial/upgrade.json`](script/releases/v1.0.0-initial/upgrade.json)
- [`script/releases/v2.0.0-upgrade/upgrade.json`](script/releases/v2.0.0-upgrade/upgrade.json)

## Executing Deployments

### 1. Test Deployment Script

Before actual deployment, test your script:

```bash
zeus test --env testnet-sepolia script/releases/v1.0.0-initial/1-deploy.s.sol
```

### 2. Deploy Upgrade

```bash
zeus deploy run --upgrade v1.0.0-initial --env testnet-sepolia
```

**Deployment Process:**
1. **Configuration**: Enter RPC URL and private key
2. **Simulation**: Zeus runs a mock deployment
3. **Confirmation**: Review deployment details
4. **Execution**: Actual deployment to blockchain
5. **Verification**: Optional Etherscan verification

**Example interaction:**
```bash
✔ [choose method] Enter an RPC url (or $ENV_VAR) for Sepolia 
? How would you like to perform this upgrade?
❯ Signing w/ private key
  Signing w/ ledger

Simulation Deployed Contracts: 
┌─────────┬──────────────────────────────────────────────┬─────────────────┬───────────┐
│ (index) │ address                                      │ contract        │ singleton │
├─────────┼──────────────────────────────────────────────┼─────────────────┼───────────┤
│ 0       │ '0x0A4B3c709D84B6570326FcB07aE255F30D2A641d' │ 'Counter_Impl'  │ true      │
│ 1       │ '0x04c614598Bc353a94469A830aB05D5363E3de129' │ 'Counter_Proxy' │ true      │
└─────────┴──────────────────────────────────────────────┴─────────────────┴───────────┘

? Would you like to continue? yes
```

### 3. Monitor Deployment

```bash
# Check deployment status
zeus deploy status --env testnet-sepolia

# Resume interrupted deployment
zeus deploy run --resume --env testnet-sepolia

# Cancel deployment
zeus deploy cancel --env testnet-sepolia
```

### 4. Verify Deployment

```bash
zeus deploy verify --env testnet-sepolia
```

## Contract Upgrades

### 1. Register Upgrade

```bash
zeus upgrade register
```

**Example for v2.0.0 upgrade:**
```bash
✔ Upgrade directory? v2.0.0-upgrade
Creating the following upgrade:
        counter-upgrade-v2
                requires: 1.0.0
                upgrades to: 2.0.0
                pinned to commit: feat/zeus@ad56261

                Deploy phases:
                        1. 1-upgrade.s.sol
✔ Save? yes
+ created upgrade (counter-upgrade-v2)
```

### 2. Test Upgrade Script

```bash
zeus test --env testnet-sepolia script/releases/v2.0.0-upgrade/1-upgrade.s.sol
```

### 3. Execute Upgrade

```bash
zeus deploy run --upgrade v2.0.0-upgrade --env testnet-sepolia
```

**Note**: Ensure the previous version (v1.0.0) is already deployed, as specified in the upgrade requirements.

## Environment Commands Reference

```bash
# Environment management
zeus env new                           # Create new environment
zeus env list                         # List all environments
zeus env show <env-name>              # Show environment details

# Upgrade management
zeus upgrade register                  # Register new upgrade
zeus upgrade list --env <env-name>    # List available upgrades

# Deployment
zeus test --env <env> <script>        # Test deployment script
zeus deploy run --upgrade <name> --env <env>  # Deploy upgrade
zeus deploy run --resume --env <env>  # Resume deployment
zeus deploy status --env <env>        # Check deployment status
zeus deploy cancel --env <env>        # Cancel deployment
zeus deploy verify --env <env>        # Verify deployed contracts
```

## Troubleshooting

### 1. Artifact Read Error

**Problem:**
```bash
Error: failed to read artifact source file for `/path/to/contract.sol`
```

**Solution:**
```bash
forge clean
forge build
```

### 2. Non-main Branch Warning

**Problem:**
```bash
Warning: You are currently on (feat/zeus), while the default branch is origin/main.
```

**Solutions:**
1. Continue on current branch (others will need to checkout this branch to apply the upgrade)
2. Merge to main branch first, then register the upgrade

### 3. Existing Deploy in Progress

**Problem:**
```bash
Existing deploy in progress. Please rerun with --resume
```

**Solutions:**
```bash
# Resume the deployment
zeus deploy run --resume --env <env-name>

# Or cancel if you're sure it's complete/failed
zeus deploy cancel --env <env-name>
```

### 4. State Update Conflict

**Problem:**
```bash
[txn] warning: an update occurred while you were modifying state
An unknown error occurred while performing the deploy
```

**Solution:**
This usually indicates concurrent modifications to the metadata repository. Wait a moment and retry the deployment.

### 5. Best Practices

- **Always test scripts** before actual deployment using `zeus test`
- **Separate verification** from deployment if Etherscan verification fails
- **Review simulation results** carefully before confirming deployment

## Additional Resources

- [Zeus Official Documentation](https://layr-labs.github.io/zeus/)
- [Zeus Templates Repository](https://github.com/Layr-Labs/zeus-templates)
- [Template Deployment Scripts](script/releases/)
- [Environment Helper Library](script/releases/Env.sol)