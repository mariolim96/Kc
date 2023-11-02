// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import '../types/CarbonProjectTypes.sol';

abstract contract CarbonProjectsStorage {
    uint128 public projectTokenCounter;
    uint128 public totalSupply;
    address public contractRegistry;
    string public baseURI;

    /// @dev maps `tokenId` to `ProjectData` struct
    mapping(uint256 => ProjectData) public projectData;

    /// @dev uniqueness check for globalUniqueIdentifier strings
    /// Example: `'VCS-01468' -> true`
    /// Todo: assess if can be deprecated
    mapping(string => bool) public projectIds;

    /// @dev mapping to identify invalid projectTokenIds
    /// Examples: projectokenIds that have been removed or non-existent ones
    mapping(uint256 => bool) public validProjectTokenIds;

    /// @dev Maps a universal/global project-id like 'VCS-1234' to its `tokenId`
    mapping(string => uint256) public pidToTokenId;
}
