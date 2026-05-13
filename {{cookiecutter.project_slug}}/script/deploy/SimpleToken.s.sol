// SPDX-License-Identifier: {{ cookiecutter.spdx_license_identifier }}
pragma solidity 0.8.30;

import { Script, console2 } from "forge-std/Script.sol";
import { SimpleToken } from "../../src/SimpleToken.sol";

/**
 * @title SimpleTokenDeploy
 * @dev Deployment script for SimpleToken on Tenderly Virtual TestNets
 * This script is optimized for CI/CD workflows with automatic verification
 */
contract SimpleTokenDeploy is Script {
    SimpleToken public token;

    function setUp() public { }

    function run() public {
        // No-arg broadcast: forge uses whatever CLI signer was passed
        // (--account / --ledger / --private-key), so this works on every
        // signing path. deploy.sh wires that up.
        vm.startBroadcast();

        // Deploy SimpleToken with demo parameters
        token = new SimpleToken(
            "Tenderly Demo Token", // name
            "TDT", // symbol
            18, // decimals
            1000000 // total supply (1M tokens)
        );

        console2.log("SimpleToken deployed to:", address(token));
        console2.log("Token name:", token.name());
        console2.log("Token symbol:", token.symbol());
        console2.log("Total supply:", token.totalSupply());
        console2.log("Deployer balance:", token.balanceOf(msg.sender));

        vm.stopBroadcast();

        // Verification info for Tenderly
        console2.log("=== Deployment Summary ===");
        console2.log("Contract: SimpleToken");
        console2.log("Address:", address(token));
        console2.log("Chain ID:", block.chainid);
        console2.log("Block Number:", block.number);
        console2.log("Deployer:", msg.sender);
    }
}
