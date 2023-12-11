// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

interface IPoolFilter {
    function checkEligible(address erc20Addr) external view returns (bool);

    function minimumVintageStartTime() external view returns (uint64);

    function regions(string calldata region) external view returns (bool);

    function standards(string calldata standard) external view returns (bool);

    function methodologies(string calldata methodology) external view returns (bool);
}
