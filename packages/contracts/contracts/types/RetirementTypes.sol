//  SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

struct RetirementRequestParams {
    uint256 tokenId;
    uint256 amount;
    string retiringEntityString;
    address beneficiary;
    string beneficiaryString;
    string retirementMessage;
}

struct RetirementsData {
    address retiringEntity;
    address beneficiary;
    string retiringEntityString;
    string beneficiaryString;
    string retirementMessage;
    uint256 amount;
    uint256 retiremenId;
    uint256 createdAt;
}
