// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

abstract contract CarbonOffsetFactoryStorage {
    address public registryAddress;
    address[] public deployedContracts;
    // from projectVintageTokenId to ERC20 address deployed
    mapping(uint256 => address) public _pvIdtoERC20;
    address public beacon;

    address public bridgeFeeReceiver;
    uint256 public bridgeFeePercentageInBase;
    address public bridgeFeeBurnAddress;
    uint256 public bridgeFeeBurnPercentageInBase;
    uint256[48] private __gap;
}
