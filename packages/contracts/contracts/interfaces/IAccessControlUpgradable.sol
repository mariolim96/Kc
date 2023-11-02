// SPDX-License-Identifier: Unlicense
import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import {IAccessControl} from '@openzeppelin/contracts/access/IAccessControl.sol';
pragma solidity ^0.8.20;

interface IAccessControlUpgradeable is IAccessControl, IERC165 {
    // function hasRole(bytes32 role, address account) external view returns (bool);
    // function getRoleAdmin(bytes32 role) external view returns (bytes32);
    // function grantRole(bytes32 role, address account) external;
    // function revokeRole(bytes32 role, address account) external;
    // function renounceRole(bytes32 role, address callerConfirmation) external;
}
