// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

interface IRetirementCertificates {
    function mintCertificate(
        address retiringEntity,
        string calldata retiringEntityString,
        address beneficiary,
        string calldata beneficiaryString,
        string calldata retirementMessage,
        uint256[] calldata retirementEventIds
    ) external returns (uint256);

    // function mintCertificateWithExtraData(
    //     address retiringEntity,
    //     CreateRetirementRequestParams calldata params,
    //     uint256[] calldata retirementEventIds
    // ) external returns (uint256);

    function registerEvent(
        address retiringEntity,
        uint256 projectVintageTokenId,
        uint256 amount,
        bool isLegacy
    ) external returns (uint256 retireEventCounter);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}
