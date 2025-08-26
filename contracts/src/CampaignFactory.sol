// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Campaign} from "./Campaign.sol";

contract CampaignFactory {
    event CampaignCreated(address indexed campaign, address indexed owner, Campaign.Params params);

    address public immutable verifier;

    constructor(address _verifier) {
        verifier = _verifier;
    }

    function createCampaign(Campaign.Params memory params) external returns (address) {
        Campaign c = new Campaign(msg.sender, verifier, params);
        emit CampaignCreated(address(c), msg.sender, params);
        return address(c);
    }
}
