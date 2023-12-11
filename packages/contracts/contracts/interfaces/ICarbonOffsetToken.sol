// SPDX-FileCopyrightText: 2022 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <security@toucan.earth> or visit security.toucan.earth
pragma solidity 0.8.20;

import '../types/VintageData.sol';
import '../types/CarbonProjectTypes.sol';
import '../types/RetirementTypes.sol';

interface ICarbonOffsets {
    function retireFrom(address account, uint256 amount) external returns (uint256 retirementEventId);

    function burnFrom(address account, uint256 amount) external;

    function getAttributes() external view returns (ProjectData memory, VintageData memory);

    function standardRegistry() external view returns (string memory);

    function retireAndMintCertificate(
        string calldata retiringEntityString,
        address beneficiary,
        string calldata beneficiaryString,
        string calldata retirementMessage,
        uint256 amount
    ) external;

    function retireAndMintCertificateForEntity(
        address retiringEntity,
        RetirementRequestParams calldata params
    ) external;

    function projectVintageTokenId() external view returns (uint256);
}
