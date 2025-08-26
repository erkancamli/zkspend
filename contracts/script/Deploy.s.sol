// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/CampaignFactory.sol";
import "../src/VerifierStub.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();
        VerifierStub verifier = new VerifierStub();
        CampaignFactory factory = new CampaignFactory(address(verifier));
        console2.log("VerifierStub:", address(verifier));
        console2.log("CampaignFactory:", address(factory));
        vm.stopBroadcast();
    }
}
