// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

abstract contract CarbonOffsetsStorage {
    uint256 internal _carbonTokenizerId;
    address public contractRegistry;
    mapping(address => uint256) public minterToId;
}
