// SPDX-License-Identifier: {{ cookiecutter.spdx_license_identifier }}
pragma solidity 0.8.30;

import { Script, console } from "forge-std/Script.sol";

/// @notice Default deployment script. Replace the body of `run` with your
///         contract deployments and run with:
///
///   script/deploy/deploy.sh script/deploy/Deploy.s.sol --account <name>
///
///         (see `script/deploy/deploy.sh --help`).
contract Deploy is Script {
    function run() external {
        vm.startBroadcast();
        console.log("Deploying from:", msg.sender);
        // TODO: deploy your contracts here, e.g.
        //
        //   MyContract c = new MyContract(...);
        //   console.log("MyContract:", address(c));
        vm.stopBroadcast();
    }
}
