// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;
import '../types/CarbonTokenizer.types.sol';

abstract contract ICarbonTokenizer {
    function getVintageTokenIdByTokenId(uint256 tokenId) external view virtual returns (batchTokenized memory);

    function fractionalize(uint256 vintageTokenId) external virtual;

    function getVintageInfo(
        uint256 vintageTokenizedId
    ) external view virtual returns (uint256 tokenId, uint256 amount, Status status);
}
