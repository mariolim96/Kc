// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.20;

// import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

interface ICarbonOffsetsFactory {
    function bridgeFeeReceiverAddress() external view returns (address receiver);

    function getBridgeFeeBurnAddress() external view returns (address burner);

    function getBridgeFeeAndBurnAmount(uint256 quantity) external view returns (uint256 feeAmount, uint256 burnAmount);

    function owner() external view returns (address);

    function pvIdtoERC20(uint256 pvId) external view returns (address);

    function deployFromVintage(uint256 projectVintageTokenId) external;
}
