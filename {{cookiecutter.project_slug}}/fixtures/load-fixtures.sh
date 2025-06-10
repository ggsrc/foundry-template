#!/bin/bash

# Tenderly CI/CD Helper Functions
# This script provides utilities for Tenderly Virtual TestNet operations

set_wallet_balance() {
    if [ "$#" -ne 3 ]; then
        echo "Usage: set_wallet_balance RPC_URL WALLET_ADDRESS BALANCE_HEX"
        return 1
    fi

    local rpc_url="$1"
    local wallet_address="$2"
    local balance_hex="$3"

    echo "Setting balance for $wallet_address to $balance_hex"
    
    curl --location "$rpc_url" \
        --header 'Content-Type: application/json' \
        --data "{
            \"jsonrpc\": \"2.0\",
            \"method\": \"tenderly_setBalance\",
            \"params\": [\"$wallet_address\", \"$balance_hex\"],
            \"id\": \"1\"
        }"
}

update_foundry_config_and_build() {
    if [ "$#" -ne 3 ]; then
        echo "Usage: update_foundry_config_and_build ACCESS_KEY VERIFICATION_URL CHAIN_ID"
        return 1
    fi

    local access_key="$1"
    local verification_url="$2"
    local chain_id="$3"

    echo "Updating foundry.toml with chain ID: $chain_id"
    echo "Verification URL: $verification_url"

    # Create temporary file and update foundry.toml
    sed -e "s|\${TENDERLY_ACCESS_KEY}|$access_key|g" \
        -e "s|\${TENDERLY_FOUNDRY_VERIFICATION_URL}|$verification_url|g" \
        -e "s/\(unknown_chain[[:space:]]*=[[:space:]]*{[^}]*chain[[:space:]]*=[[:space:]]*\)[0-9][0-9]*/\1$chain_id/g" \
        foundry.toml > foundry.toml.tmp && mv foundry.toml.tmp foundry.toml

    echo "✅ foundry.toml updated successfully"
    
    # Build contracts
    echo "Building contracts..."
    forge build --sizes
}

# Export constants
export HUNDRED_ETH="0xDE0B6B3A7640000"  # 100 ETH in hex wei
export TEN_ETH="0x8AC7230489E80000"     # 10 ETH in hex wei
export ONE_ETH="0xDE0B6B3A7640000"      # 1 ETH in hex wei

echo "Tenderly fixtures loaded successfully!"
echo "Available functions: set_wallet_balance, update_foundry_config_and_build"
echo "Available constants: HUNDRED_ETH, TEN_ETH, ONE_ETH" 