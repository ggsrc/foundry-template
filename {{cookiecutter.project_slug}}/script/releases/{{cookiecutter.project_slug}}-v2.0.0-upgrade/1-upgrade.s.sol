// SPDX-License-Identifier: {{ cookiecutter.spdx_license_identifier }}
pragma solidity 0.8.30;

import { EOADeployer } from "@zeus-templates/templates/EOADeployer.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import "@src/CounterV2.sol";
import "../Env.sol";
import { console2 } from "forge-std/Script.sol";
import { ProxyHelper } from "../../utils/ProxyHelper.sol";

contract UpgradeToV2 is EOADeployer {
    using Env for Env.DeployedProxy;
    using Env for Env.DeployedImpl;
    using ProxyHelper for address;

    // Store deployed V2 implementation address for validation
    address public deployedImplementationV2;

    function _runAsEOA() internal override {
        // Get deployer address to ensure using same account for upgrade
        address deployer = Env.deployer();

        // Start broadcast using deployer account
        vm.startBroadcast(deployer);

        // 1. Deploy new implementation contract V2
        deployedImplementationV2 = address(new CounterV2());
        deployImpl({
            name: type(CounterV2).name, // Use actual contract name "CounterV2"
            deployedTo: deployedImplementationV2
        });

        // 2. Use Env helper library to get ProxyAdmin and proxy contract
        ProxyAdmin admin = Env.getProxyAdminContract();
        Counter counterProxy = Env.proxy.counter();

        // 3. Update proxy implementation
        admin.upgradeAndCall(
            ITransparentUpgradeableProxy(address(counterProxy)),
            deployedImplementationV2,
            "" // Empty data, no function call
        );

        // 4. Output upgrade information
        console2.log("Network:", block.chainid);
        console2.log("CounterV2 implementation deployed to:", deployedImplementationV2);
        console2.log("Proxy at", address(counterProxy), "upgraded to new implementation");
        console2.log("Environment type:", Env.isTestEnvironment() ? "test" : "production");

        vm.stopBroadcast();
    }

    // Comprehensive test function, similar to testScript in examples
    function testScript() public {
        // Run upgrade script
        this.runAsEOA();

        // Execute various validations
        _validateUpgrade();
        _validateImplementation();
        _validateInitialization();
        _validateFunctionality();
        _validateVersion();
    }

    // Validate upgrade was successful
    function _validateUpgrade() internal view {
        // Get contract instances
        Counter counterProxy = Env.proxy.counter();

        // Validate proxy now points to new implementation
        address currentImpl = _getProxyImpl(address(counterProxy));
        assertTrue(currentImpl == deployedImplementationV2, "Proxy implementation not upgraded");
    }

    // Validate implementation contract constructor setup
    function _validateImplementation() internal view {
        CounterV2 counterV2Impl = CounterV2(deployedImplementationV2);

        // Validate implementation contract exists
        assertTrue(address(counterV2Impl).code.length > 0, "Implementation V2 contract has no code");
    }

    // Validate initialization is correct
    function _validateInitialization() internal {
        CounterV2 counterV2Impl = CounterV2(deployedImplementationV2);

        // Validate implementation contract initialization function is disabled (OpenZeppelin v5 uses custom errors)
        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        counterV2Impl.initialize(address(0));
    }

    // Validate contract functionality is working
    function _validateFunctionality() internal {
        // Validate upgraded contract functionality
        Counter counterProxy = Env.proxy.counter();
        CounterV2 counterV2 = CounterV2(address(counterProxy));

        // Test original increment functionality
        uint256 initialCount = counterV2.getCount();
        counterV2.increment();
        assertEq(counterV2.getCount(), initialCount + 1, "Increment function failed");

        // Test new decrement functionality
        uint256 currentCount = counterV2.getCount();
        counterV2.decrement();
        assertEq(counterV2.getCount(), currentCount - 1, "Decrement function failed");
    }

    // Validate contract version
    function _validateVersion() internal view {
        Counter counterProxy = Env.proxy.counter();
        assertEq(counterProxy.version(), "v2.0.0", "Version not updated to v2.0.0");
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
