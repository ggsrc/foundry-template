// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { EOADeployer } from "@zeus-templates/templates/EOADeployer.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import "@src/Counter.sol";
import "../Env.sol";
import { console2 } from "forge-std/Script.sol";
import { ProxyHelper } from "../../utils/ProxyHelper.sol";

contract InitialDeploy is EOADeployer {
    using Env for Env.DeployedProxy;
    using Env for Env.DeployedImpl;
    using ProxyHelper for address;

    // Store deployed addresses for validation
    address public deployedImplementation;
    address public deployedProxy;
    address public deployedProxyAdmin;

    function _runAsEOA() internal override {
        // Start broadcast
        vm.startBroadcast();

        // 2. Deploy implementation contract
        deployedImplementation = address(new Counter());
        deployImpl({ name: type(Counter).name, deployedTo: deployedImplementation });

        // 3. Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(Counter.initialize.selector, Env.deployer());

        // 4. Deploy proxy contract (automatically creates ProxyAdmin)
        deployedProxy = address(new TransparentUpgradeableProxy(deployedImplementation, msg.sender, initData));
        deployProxy({ name: "Counter", deployedTo: deployedProxy });

        // 5. Get actual ProxyAdmin address and store it
        deployedProxyAdmin = _getProxyAdmin(deployedProxy);
        zUpdate("PROXY_ADMIN", deployedProxyAdmin);
        zUpdate("DEPLOYER", msg.sender);
        zUpdate("ENVIRONMENT_TYPE", Env.isTestEnvironment() ? "test" : "production");

        // 6. Output deployment information
        console2.log("Network:", block.chainid);
        console2.log("ProxyAdmin deployed to:", deployedProxyAdmin);
        console2.log("Counter implementation deployed to:", deployedImplementation);
        console2.log("Counter proxy deployed to:", deployedProxy);

        vm.stopBroadcast();
    }

    // Comprehensive test function, similar to testScript in examples
    function testScript() public {
        // Run deployment
        this.runAsEOA();

        // Execute various validations
        _validateProxySetup();
        _validateImplementation();
        _validateInitialization();
        _validateFunctionality();
        _validateVersion();
    }

    // Validate proxy setup is correct
    function _validateProxySetup() internal view {
        // Get contract instances using deployed addresses
        ProxyAdmin admin = ProxyAdmin(deployedProxyAdmin);
        Counter counterProxy = Counter(deployedProxy);

        // Validate proxy admin
        address proxyAdmin = _getProxyAdmin(address(counterProxy));
        assertTrue(proxyAdmin == address(admin), "Proxy admin address mismatch");

        // Validate proxy implementation
        address currentImpl = _getProxyImpl(address(counterProxy));
        assertTrue(currentImpl == deployedImplementation, "Proxy implementation mismatch");
    }

    // Validate implementation contract constructor setup
    function _validateImplementation() internal view {
        Counter counterImpl = Counter(deployedImplementation);

        // Validate implementation contract exists
        assertTrue(address(counterImpl).code.length > 0, "Implementation contract has no code");
    }

    // Validate initialization is correct
    function _validateInitialization() internal {
        Counter counterImpl = Counter(deployedImplementation);

        // Validate implementation contract initialization function is disabled (OpenZeppelin v5 uses custom errors)
        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        counterImpl.initialize(address(0));

        // Validate proxy contract is properly initialized
        Counter counterProxy = Counter(deployedProxy);
        assertEq(counterProxy.getCount(), 0, "Counter not initialized to 0");
    }

    // Validate contract functionality is working
    function _validateFunctionality() internal {
        Counter counterProxy = Counter(deployedProxy);

        // Test counter functionality
        uint256 initialCount = counterProxy.getCount();
        counterProxy.increment();
        assertEq(counterProxy.getCount(), initialCount + 1, "Increment function failed");
    }

    // Validate contract version
    function _validateVersion() internal view {
        Counter counterProxy = Counter(deployedProxy);
        assertEq(counterProxy.version(), "v1.0.0", "Version mismatch");
    }

    /// @dev Query and return proxy implementation address
    function _getProxyImpl(
        address proxy
    ) internal view returns (address) {
        return proxy.getProxyImplementation();
    }

    /// @dev Query and return proxy admin address
    function _getProxyAdmin(
        address proxy
    ) internal view returns (address) {
        return proxy.getProxyAdmin();
    }
}
