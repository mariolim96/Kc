// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import {IProjectVintages} from './interfaces/IProjectVintages.sol';
import {VintageData} from './types/VintageData.sol';
import {ProjectVintagesStorage} from './storages/ProjectVintages.storage.sol';
import './libraries/Modifiers.sol';
import './libraries/ProjectUtils.sol';

import './interfaces/IRegistry.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import {IAccessControlUpgradeable} from './interfaces/IAccessControlUpgradable.sol';

abstract contract ProjectVintages is
    ProjectVintagesStorage,
    ERC721Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    IAccessControlUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    Modifiers,
    ProjectUtils,
    IProjectVintages
{
    string public constant VERSION = '1.0';
    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');
    // ----------------------------------------
    //      Events
    // ----------------------------------------
    event ProjectVintageMinted(address receiver, uint256 tokenId, uint256 projectTokenId, uint64 startTime);
    event ProjectVintageUpdated(uint256 tokenId);

    // ----------------------------------------
    //      Upgradable related functions
    // ----------------------------------------
    // @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() external virtual initializer {
        __Context_init_unchained();
        __ERC721_init_unchained('Toucan Protocol: Carbon Project Vintages', 'TOUCAN-CPV');
        __Ownable_init_unchained(msg.sender);
        __Pausable_init_unchained();
        __AccessControl_init_unchained();
        __UUPSUpgradeable_init_unchained();
        /// @dev granting the deployer==owner the rights to grant other roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControlUpgradeable, ERC721Upgradeable, IERC165) returns (bool) {
        return
            interfaceId == type(IAccessControlUpgradeable).interfaceId ||
            ERC721Upgradeable.supportsInterface(interfaceId);
    }

    //--------------------------
    //      Admin functions
    // ------------------------

    /// @dev modifier that only lets the contract's owner and elected managers add/update/remove project data
    modifier onlyManagers() {
        require(hasRole(MANAGER_ROLE, msg.sender) || owner() == msg.sender, 'Caller is not authorized');
        _;
    }

    // ----------------------------------------
    //      Internal functions
    // ----------------------------------------
    function setToucanContractRegistry(address _address) external virtual onlyOwner {
        contractRegistry = _address;
    }

    // ----------------------------------------
    //      External functions
    // ----------------------------------------
    /// @notice Adds a new carbon project-vintage along with attributes/data
    /// @dev vintages can be added by data-managers
    function addNewVintage(
        address to,
        VintageData memory _vintageData
    ) external virtual onlyManagers whenNotPaused returns (uint256) {
        checkProjectTokenExists(contractRegistry, _vintageData.projectTokenId);

        require(pvToTokenId[_vintageData.projectTokenId][_vintageData.startTime] == 0, 'Error: vintage already added');

        require(_vintageData.startTime < _vintageData.endTime, 'Error: vintage startTime must be less than endTime');

        /// @dev Increase `projectVintageTokenCounter` and mark current Id as valid
        uint256 newItemId = projectVintageTokenCounter;
        unchecked {
            ++newItemId;
            ++totalSupply;
        }
        projectVintageTokenCounter = uint128(newItemId);

        validProjectVintageIds[newItemId] = true;

        _mint(to, newItemId);

        vintageData[newItemId] = _vintageData;
        emit ProjectVintageMinted(to, newItemId, _vintageData.projectTokenId, _vintageData.startTime);
        pvToTokenId[_vintageData.projectTokenId][_vintageData.startTime] = newItemId;

        return newItemId;
    }

    // /// @dev Removes a project-vintage and corresponding data
    function removeVintage(uint256 tokenId) external virtual onlyManagers whenNotPaused {
        totalSupply--;
        delete vintageData[tokenId];
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return validProjectVintageIds[tokenId] == true;
    }

    // /// @dev retrieve all data from VintageData struct
    function getProjectVintageDataByTokenId(uint256 tokenId) external view returns (VintageData memory) {
        require(_ownerOf(tokenId) != address(0), 'Project not yet minted');
        return vintageData[tokenId];
    }

    function updateProjectVintage(
        uint256 tokenId,
        VintageData memory _vintageData
    ) external virtual onlyManagers whenNotPaused {
        require(_ownerOf(tokenId) != address(0), 'Project not yet minted');
        // @dev very sensitive data, better update via separate function
        _vintageData.projectTokenId = vintageData[tokenId].projectTokenId;
        vintageData[tokenId] = _vintageData;

        emit ProjectVintageUpdated(tokenId);
    }
}

// {

//     /// @notice Emergency function to disable contract's core functionality
//     /// @dev wraps _pause(), only Admin
//     function pause() external virtual onlyBy(contractRegistry, owner()) {
//         _pause();
//     }

//     /// @dev unpause the system, wraps _unpause(), only Admin
//     function unpause() external virtual onlyBy(contractRegistry, owner()) {
//         _unpause();
//     }

//     function _baseURI() internal view virtual override returns (string memory) {
//         return baseURI;
//     }

//     function setBaseURI(string memory baseURI_) external virtual onlyOwner {
//         baseURI = baseURI_;
//     }

//     /// @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
//     /// based on the ERC721URIStorage implementation
//     function tokenURI(uint256 tokenId)
//         public
//         view
//         virtual
//         override
//         returns (string memory)
//     {
//         require(
//             _exists(tokenId),
//             'ERC721URIStorage: URI query for nonexistent token'
//         );

//         string memory uri = vintageData[tokenId].uri;
//         string memory base = _baseURI();

//         // If there is no base URI, return the token URI.
//         if (bytes(base).length == 0) {
//             return uri;
//         }
//         // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
//         if (bytes(uri).length > 0) {
//             return string(abi.encodePacked(base, uri));
//         }

//         return super.tokenURI(tokenId);
//     }
// }
