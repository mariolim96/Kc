// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;
import {RetirementRequestParams} from '../types/RetirementTypes.sol';

interface IRetirementCertificates {
    function mintCertificate(address retiringEntity, RetirementRequestParams memory params) external returns (uint256);

    // function safeTransferFrom(address from, address to, uint256 tokenId) external;
}
