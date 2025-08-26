// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IVerifier {
    function verify(bytes calldata proof, bytes32 publicInputHash) external view returns (bool);
}

library Bytes32Set {
    struct Set { mapping(bytes32 => bool) _has; }
    function add(Set storage s, bytes32 k) internal returns (bool) {
        if (s._has[k]) return false;
        s._has[k] = true; return true;
    }
    function has(Set storage s, bytes32 k) internal view returns (bool) { return s._has[k]; }
}

contract Campaign {
    using Bytes32Set for Bytes32Set.Set;

    struct Params {
        bytes32 merchantRoot;     // merkle root of allowed merchants
        uint256 minAmount;        // in smallest unit (e.g., cents)
        uint64  startTime;
        uint64  endTime;
        address rewardToken;      // ERC20 or address(0) for native
        uint256 rewardAmount;     // fixed reward per valid claim (MVP)
        address treasury;         // funds the rewards
    }

    event Claimed(address indexed user, bytes32 receiptCommitment, bytes32 nullifier);
    event Withdrawn(address indexed to, uint256 amount);

    address public immutable owner;
    address public immutable verifier;
    Params  public params;

    mapping(address => bool) public allowEOA; // optional allowlist for beta
    Bytes32Set.Set private _usedNullifiers;

    constructor(address _owner, address _verifier, Params memory _params) {
        require(_params.startTime < _params.endTime, "bad window");
        owner = _owner; verifier = _verifier; params = _params;
    }

    modifier onlyOwner() { require(msg.sender == owner, "not owner"); _; }

    function setEOA(address user, bool ok) external onlyOwner { allowEOA[user] = ok; }

    /// @notice Claim with zk proof over the committed receipt fields.
    /// @param proof ZK proof bytes (opaque to the contract; verified by Verifier)
    /// @param publicInputHash keccak256(abi.encode(merchantRoot, minAmount, startTime, endTime, receiptCommitment, nullifier, msg.sender))
    /// @param receiptCommitment commitment to minimal fields (merchantId, amount, date, salt)
    /// @param nullifier unique per-receipt (prevents double claim)
    function claim(bytes calldata proof, bytes32 publicInputHash, bytes32 receiptCommitment, bytes32 nullifier) external payable {
        // optional beta gate
        if (allowEOA[msg.sender] == false) {
            // allow if unset (false) only when no allowlist is used; comment out to enforce gate
        }

        require(block.timestamp >= params.startTime && block.timestamp <= params.endTime, "inactive");
        require(!_usedNullifiers.has(nullifier), "spent");

        // Verify zk proof
        bool ok = IVerifier(verifier).verify(proof, publicInputHash);
        require(ok, "bad proof");

        // mark nullifier used
        _usedNullifiers.add(nullifier);

        // Payout (MVP: native only for simplicity)
        if (params.rewardToken == address(0)) {
            (bool s, ) = msg.sender.call{value: params.rewardAmount}("");
            require(s, "xfer failed");
        } else {
            // ERC20 transferFrom treasury in production; omitted in MVP
        }

        emit Claimed(msg.sender, receiptCommitment, nullifier);
    }

    // Treasury top-up (native)
    receive() external payable {}

    function withdraw(uint256 amount, address payable to) external onlyOwner {
        (bool s, ) = to.call{value: amount}(""); require(s, "withdraw fail");
        emit Withdrawn(to, amount);
    }
}
