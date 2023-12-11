// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

abstract contract PoolStorageV1 {
    /// @notice The supply cap is used as a measure to guard deposits
    /// in the pool. It is meant to minimize the impact a potential
    /// compromise in the source registry (eg. Verra) can have to the pool.
    uint256 public supplyCap;
    /// @notice array used to read from when redeeming TCO2s automatically
    address[] public scoredTCO2s;

    /// @dev fees redeem receiver address
    address public feeRedeemReceiver;
    uint256 public feeRedeemPercentageInBase;
    /// @dev fees redeem burn address
    address public feeRedeemBurnAddress;
    /// @dev fees redeem burn percentage with 2 fixed decimals precision
    uint256 public feeRedeemBurnPercentageInBase;

    /// @notice End users exempted from redeem fees
    mapping(address => bool) public redeemFeeExemptedAddresses;
    /// @notice TCO2s exempted from redeem fees
    mapping(address => bool) public redeemFeeExemptedTCO2s;

    /// @notice fee percentage in basis points charged for selective
    /// redemptions that also retire the credits in the same transaction
    uint256 public feeRedeemRetirePercentageInBase;
    address public filter;
}

abstract contract PoolStorage is PoolStorageV1 {}
