// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;
import '../types/Retirement.types.sol';

abstract contract RetirementCertificatesStorageV1 {
    /// @dev a RetirementEvent has a clear ownership relationship.
    /// This relation is less clear in an NFT that already has a beneficiary set
    struct RetirementEvent {
        uint256 createdAt;
        address retiringEntity;
        /// @dev amount is denominated in 18 decimals, similar to amounts
        /// in TCO2 contracts.
        uint256 amount;
        uint256 projectVintageTokenId;
    }

    /// @dev id that tracks retirement events
    uint256 public retireEventCounter;

    /// @dev maps the retireEventCounter to the RetirementEvent data
    mapping(uint256 => RetirementEvent) public retirements;

    /// @dev mapping that helps ensure retirement events are not claimed multiple times
    mapping(uint256 => bool) public claimedEvents;

    /// @dev List all the events belonging to user (maybe this could be better inferred via a subgraph)
    mapping(address => uint256[]) eventsOfUser;

    string public baseURI;
    address public contractRegistry;
    uint256 internal _tokenIds;

    mapping(uint256 => DataRetirement) public certificates;

    uint256 public minValidRetirementAmount;
}

/// @dev Kept separate from RetirementCertificatesStorageV1 to
/// add ReentrancyGuardUpgradeable in between.
abstract contract RetirementCertificatesStorage {

}
