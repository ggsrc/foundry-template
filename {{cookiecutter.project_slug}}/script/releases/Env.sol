// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Vm.sol";
import "@zeus-templates/utils/ZEnvHelpers.sol";

import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

/// Import Counter contracts
import "src/Counter.sol";
import "src/CounterV2.sol";

/**
 * @title Env
 * @notice Environment variable access library for Zeus deployment framework
 * @dev This library provides a unified interface to access deployed contracts and environment variables
 *      Uses ZEnvHelpers under the hood for actual environment variable resolution
 */
library Env {
    using ZEnvHelpers for *;

    /// Enum types for elegant access syntax, e.g.: `Env.proxy.counter()`
    /// @dev These enums are used purely for syntax sugar and type safety
    enum DeployedProxy {
        A
    }
    enum DeployedBeacon {
        A
    }
    enum DeployedImpl {
        A
    }
    enum DeployedInstance {
        A
    }

    DeployedProxy internal constant proxy = DeployedProxy.A;
    DeployedBeacon internal constant beacon = DeployedBeacon.A;
    DeployedImpl internal constant impl = DeployedImpl.A;
    DeployedInstance internal constant instance = DeployedInstance.A;

    /**
     * Environment variable access functions
     */

    /**
     * @notice Get the deployment version from environment
     * @dev Reads ZEUS_DEPLOY_TO_VERSION environment variable
     * @return The semver version string for the current deployment
     */
    function deployVersion() internal view returns (string memory) {
        return _string("ZEUS_DEPLOY_TO_VERSION");
    }

    /**
     * @notice Get the executor multisig address
     * @dev Reads from executorMultisig environment variable
     * @return The address of the executor multisig wallet
     */
    function executorMultisig() internal view returns (address) {
        return _envAddress("executorMultisig");
    }

    /**
     * @notice Get the proxy admin address
     * @dev Reads from proxyAdmin environment variable
     * @return The address of the proxy admin contract
     */
    function proxyAdmin() internal view returns (address) {
        return _envAddress("proxyAdmin");
    }

    /**
     * Counter-related access functions
     */

    /**
     * @notice Access Counter proxy contract
     * @dev Looks up deployed proxy with name "Counter"
     * @return Counter contract instance at the proxy address
     */
    function counter(
        DeployedProxy
    ) internal view returns (Counter) {
        return Counter(_deployedProxy("Counter"));
    }

    /**
     * @notice Access CounterV1 implementation contract
     * @dev Looks up deployed implementation with name "Counter"
     * @return Counter V1 implementation contract instance
     */
    function counterV1Impl(
        DeployedImpl
    ) internal view returns (Counter) {
        return Counter(_deployedImpl("Counter"));
    }

    /**
     * @notice Access CounterV2 implementation contract
     * @dev Looks up deployed implementation with name "CounterV2"
     * @return CounterV2 implementation contract instance
     */
    function counterV2Impl(
        DeployedImpl
    ) internal view returns (CounterV2) {
        return CounterV2(_deployedImpl("CounterV2"));
    }

    /**
     * ProxyAdmin access
     */

    /**
     * @notice Get the ProxyAdmin contract instance
     * @dev Reads PROXY_ADMIN environment variable and returns typed contract instance
     * @return ProxyAdmin contract instance
     */
    function getProxyAdminContract() internal view returns (ProxyAdmin) {
        return ProxyAdmin(_envAddress("PROXY_ADMIN"));
    }

    /**
     * Helper functions for getting contract addresses
     */

    /**
     * @dev Internal helper to get deployed proxy address by name
     * @param name The name of the deployed proxy contract
     * @return The address of the deployed proxy
     */
    function _deployedProxy(
        string memory name
    ) private view returns (address) {
        return ZEnvHelpers.state().deployedProxy(name);
    }

    /**
     * @dev Internal helper to get deployed beacon address by name
     * @param name The name of the deployed beacon contract
     * @return The address of the deployed beacon
     */
    function _deployedBeacon(
        string memory name
    ) private view returns (address) {
        return ZEnvHelpers.state().deployedBeacon(name);
    }

    /**
     * @dev Internal helper to get deployed implementation address by name
     * @param name The name of the deployed implementation contract
     * @return The address of the deployed implementation
     */
    function _deployedImpl(
        string memory name
    ) private view returns (address) {
        return ZEnvHelpers.state().deployedImpl(name);
    }

    /**
     * Environment variable access helper functions
     */

    /**
     * @dev Internal helper to read address from environment variables
     * @param key The environment variable key to read
     * @return The address value from the environment variable
     */
    function _envAddress(
        string memory key
    ) private view returns (address) {
        return ZEnvHelpers.state().envAddress(key);
    }

    /**
     * @dev Internal helper to read uint256 from environment variables
     * @param key The environment variable key to read
     * @return The uint256 value from the environment variable
     */
    function _envU256(
        string memory key
    ) private view returns (uint256) {
        return ZEnvHelpers.state().envU256(key);
    }

    /**
     * @dev Internal helper to read uint64 from environment variables
     * @param key The environment variable key to read
     * @return The uint64 value from the environment variable
     */
    function _envU64(
        string memory key
    ) private view returns (uint64) {
        return ZEnvHelpers.state().envU64(key);
    }

    /**
     * @dev Internal helper to read uint32 from environment variables
     * @param key The environment variable key to read
     * @return The uint32 value from the environment variable
     */
    function _envU32(
        string memory key
    ) private view returns (uint32) {
        return ZEnvHelpers.state().envU32(key);
    }

    // Forge VM access
    /// @dev VM address is deterministic across all Foundry test environments
    address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    Vm internal constant vm = Vm(VM_ADDRESS);

    /**
     * @dev Internal helper to read string from environment variables using vm.envString
     * @param key The environment variable key to read
     * @return The string value from the environment variable
     */
    function _string(
        string memory key
    ) private view returns (string memory) {
        return vm.envString(key);
    }

    /**
     * Common configuration parameters
     */

    /**
     * @notice Get deployer address
     * @dev Reads DEPLOYER environment variable set during deployment
     * @return The address of the account that deployed the contracts
     */
    function deployer() internal view returns (address) {
        return _envAddress("DEPLOYER");
    }

    /**
     * @notice Get network ID
     * @dev Reads CHAIN_ID environment variable
     * @return The chain ID of the current network
     */
    function chainId() internal view returns (uint256) {
        return _envU256("CHAIN_ID");
    }

    /**
     * @notice Check if test environment
     * @dev Compares ENVIRONMENT_TYPE with "test" string
     * @return True if running in test environment, false otherwise
     */
    function isTestEnvironment() internal view returns (bool) {
        string memory envType = _string("ENVIRONMENT_TYPE");
        return keccak256(bytes(envType)) == keccak256(bytes("test"));
    }

    /**
     * @notice Check if production environment
     * @dev Compares ENVIRONMENT_TYPE with "production" string
     * @return True if running in production environment, false otherwise
     */
    function isProductionEnvironment() internal view returns (bool) {
        string memory envType = _string("ENVIRONMENT_TYPE");
        return keccak256(bytes(envType)) == keccak256(bytes("production"));
    }
}
