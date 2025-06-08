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

    function _runAsEOA() internal override {
        // Start broadcast
        vm.startBroadcast();

        // 2. Deploy implementation contract
        address implementation = deployImpl({ name: type(Counter).name, deployedTo: address(new Counter()) });

        // 3. Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(Counter.initialize.selector, Env.deployer());

        // 4. Deploy proxy contract (automatically creates ProxyAdmin)
        address proxy = deployProxy({
            name: "Counter",
            deployedTo: address(new TransparentUpgradeableProxy(implementation, msg.sender, initData))
        });

        // 5. Get actual ProxyAdmin address and store it
        address actualProxyAdmin = _getProxyAdmin(proxy);
        zUpdate("PROXY_ADMIN", actualProxyAdmin);
        zUpdate("DEPLOYER", msg.sender);
        zUpdate("ENVIRONMENT_TYPE", Env.isTestEnvironment() ? "test" : "production");

        // 6. Output deployment information
        console2.log("Network:", block.chainid);
        console2.log("ProxyAdmin deployed to:", actualProxyAdmin);
        console2.log("Counter implementation deployed to:", implementation);
        console2.log("Counter proxy deployed to:", proxy);

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
        // Get contract instances
        ProxyAdmin admin = Env.getProxyAdminContract();
        Counter counterProxy = Env.proxy.counter();

        // Validate proxy admin
        address proxyAdmin = _getProxyAdmin(address(counterProxy));
        assertTrue(proxyAdmin == address(admin), "Proxy admin address mismatch");

        // Validate proxy implementation
        address currentImpl = _getProxyImpl(address(counterProxy));
        address expectedImpl = address(Env.counterV1Impl(Env.impl));
        assertTrue(currentImpl == expectedImpl, "Proxy implementation mismatch");
    }

    // Validate implementation contract constructor setup
    function _validateImplementation() internal view {
        Counter counterImpl = Env.counterV1Impl(Env.impl);

        // Validate implementation contract exists
        assertTrue(address(counterImpl).code.length > 0, "Implementation contract has no code");
    }

    // Validate initialization is correct
    function _validateInitialization() internal {
        Counter counterImpl = Env.counterV1Impl(Env.impl);

        // Validate implementation contract initialization function is disabled (OpenZeppelin v5 uses custom errors)
        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        counterImpl.initialize(address(0));

        // Validate proxy contract is properly initialized
        Counter counterProxy = Env.proxy.counter();
        assertEq(counterProxy.getCount(), 0, "Counter not initialized to 0");
    }

    // Validate contract functionality is working
    function _validateFunctionality() internal {
        Counter counterProxy = Env.proxy.counter();

        // Test counter functionality
        uint256 initialCount = counterProxy.getCount();
        counterProxy.increment();
        assertEq(counterProxy.getCount(), initialCount + 1, "Increment function failed");
    }

    // Validate contract version
    function _validateVersion() internal view {
        Counter counterProxy = Env.proxy.counter();
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
