// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import '../types/CarbonOffsetBatchesTypes.sol';

/// @dev Separate storage contract to improve upgrade safety
abstract contract CarbonOffsetBatchesStorageV1 {
    uint256 public batchTokenCounter;
    /// @custom:oz-upgrades-renamed-from serialNumberExist
    mapping(string => bool) public serialNumberApproved;
    mapping(string => bool) private DEPRECATED_URIs;

    string public baseURI;
    address public contractRegistry;

    struct NFTData {
        uint256 projectVintageTokenId;
        string serialNumber;
        uint256 quantity;
        BatchStatus status;
        string uri;
        string[] comments;
        address[] commentAuthors;
    }

    mapping(uint256 => NFTData) public nftList;
}

abstract contract CarbonOffsetBatchesStorageV2 {
    mapping(string => bool) public supportedRegistries;
}

abstract contract CarbonOffsetBatchesStorage is CarbonOffsetBatchesStorageV1, CarbonOffsetBatchesStorageV2 {}
