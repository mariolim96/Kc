// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <security@toucan.earth> or visit security.toucan.earth
pragma solidity 0.8.20;

// abstract contract ToucanContractRegistryStorageLegacy {
//     //slither-disable-next-line uninitialized-state,constable-states
//     address internal DEPRECATED_toucanCarbonOffsetsFactoryAddress;
//     mapping(address => bool) public projectVintageERC20Registry;
// }

// abstract contract ToucanContractRegistryStorageV1 {
//     /// @dev make it easy to get the supported standard registries
//     string[] internal standardRegistries;
// }

// abstract contract ToucanContractRegistryStorageV2 {
//     address internal _toucanCarbonOffsetsEscrowAddress;
// }

abstract contract RegistryStorage {
    address internal _carbonOffsetBatchesAddress;
    address internal _carbonProjectsAddress;
    address internal _carbonProjectVintagesAddress;
    /// @notice map of standard registries to tco2 factory addresses
    mapping(string => address) public carbonOffsetFactories;
    /// @dev make it easy to get the supported standard registries
    string[] internal standardRegistries;
    address internal _retirementCertificatesAddress;
}
