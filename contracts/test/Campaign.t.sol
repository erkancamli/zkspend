// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/CampaignFactory.sol";
import "../src/VerifierStub.sol";

contract CampaignTest is Test {
    CampaignFactory factory;
    VerifierStub verifier;

    function setUp() public {
        verifier = new VerifierStub();
        factory = new CampaignFactory(address(verifier));
    }

    function testCreateAndClaim() public {
        Campaign.Params memory p = Campaign.Params({
            merchantRoot: bytes32(uint256(1)),
            minAmount: 1000,
            startTime: uint64(block.timestamp - 1),
            endTime: uint64(block.timestamp + 1 days),
            rewardToken: address(0),
            rewardAmount: 1 ether,
            treasury: address(this)
        });
        address caddr = factory.createCampaign(p);
        Campaign c = Campaign(payable(caddr));
        // fund
        (bool s,) = address(c).call{value: 5 ether}("");
        assertTrue(s);

        bytes memory proof;
        bytes32 pub = keccak256("dummy");
        bytes32 rc = keccak256("commit");
        bytes32 nul = keccak256("null");
        vm.prank(address(0xBEEF));
        c.claim(proof, pub, rc, nul);
    }
}
