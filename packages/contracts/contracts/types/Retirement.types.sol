// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

struct DataRetirement {
    uint256[] retirementEventIds;
    uint256 createdAt;
    address retiringEntity;
    address beneficiary;
    string retiringEntityString;
    string beneficiaryString;
    string retirementMessage;
    string beneficiaryLocation;
    string consumptionCountryCode;
    uint256 consumptionPeriodStart;
    uint256 consumptionPeriodEnd;
}
