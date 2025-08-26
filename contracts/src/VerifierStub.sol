// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract VerifierStub {
    // MVP: always 'verifies' true. Replace with RISC Zero verifier router.
    function verify(bytes calldata /*proof*/, bytes32 /*publicInputHash*/) external pure returns (bool) {
        return true;
    }
}
