// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <security@toucan.earth> or visit security.toucan.earth
pragma solidity 0.8.20;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import '../types/VintageData.sol';

interface IProjectVintages is IERC721 {
    function addNewVintage(address to, VintageData memory _vintageData) external returns (uint256);

    function exists(uint256 tokenId) external view returns (bool);

    function getProjectVintageDataByTokenId(uint256 tokenId) external view returns (VintageData memory);
}
