// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

// abstract contract ToucanContractRegistryStorageV1 {
//     /// @dev make it easy to get the supported standard registries
//     string[] internal standardRegistries;
// }

// abstract contract ToucanContractRegistryStorageV2 {
//     address internal _toucanCarbonOffsetsEscrowAddress;
// }

abstract contract RegistryStorage {
    address internal _carbonProjectsAddress;
    address internal _carbonProjectVintagesAddress;
    address internal _carbonTokenizerAddress;
    address internal _carbonOffsetTokenAddress;
    address internal _carbonOffsetTokenFactoryAddress;
    address internal _retirementCertificatesAddress;

    /// @notice map of standard registries to tco2 factory addresses
    mapping(string => address) public carbonOffsetFactories;
    mapping(address => bool) public projectVintageERC20Registry;
}
