// SPDX-License-Identifier: {{ cookiecutter.spdx_license_identifier }}
pragma solidity 0.8.30;

import { Script, console } from "forge-std/Script.sol";

/// @notice Default deployment script. Replace the body of `run` with your
///         contract deployments and run with:
///
///   forge script script/deploy/Deploy.s.sol \
///     --rpc-url $RPC_URL \
///     --private-key $DEPLOYER_PRIVATE_KEY \
///     --broadcast
contract Deploy is Script {
    function run() external {
        vm.startBroadcast();
        // TODO: deploy your contracts here, e.g.
        //
        //   MyContract c = new MyContract(...);
        //   console.log("MyContract:", address(c));
        vm.stopBroadcast();
    }
}
