// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

struct batchTokenized {
    uint256 projectVintageId;
    Status status;
    uint256 amount;
}
enum Status {
    inactive,
    fractionalized,
    certificated,
    active
}
