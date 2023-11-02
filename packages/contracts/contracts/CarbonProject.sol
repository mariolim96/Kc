// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.20;

import {CarbonProjectsStorage} from './storages/CarbonProject.storage.sol';
import {ICarbonProjects} from './interfaces/ICarbonProjects.sol';
import './libraries/Modifiers.sol';
import './libraries/Strings.sol';
import {ProjectData} from './types/CarbonProjectTypes.sol';

import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol';
import {IAccessControlUpgradeable} from './interfaces/IAccessControlUpgradable.sol';

// library Strings {
//     function equals(string memory a, string memory b) internal pure returns (bool) {
//         return (bytes(a).length == bytes(b).length) && (keccak256(bytes(a)) == keccak256(bytes(b)));
//     }
// }

contract CarbonProject is
    ICarbonProjects,
    CarbonProjectsStorage,
    OwnableUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    ERC721Upgradeable,
    IAccessControlUpgradeable
{
    using StringsLib for string;

    // ----------------------------------------
    //      Constants
    // ----------------------------------------

    /// @dev Version-related parameters. VERSION keeps track of production
    /// releases. VERSION_RELEASE_CANDIDATE keeps track of iterations
    /// of a VERSION in our staging environment.
    // string public constant VERSION = '1.1.1';
    // uint256 public constant VERSION_RELEASE_CANDIDATE = 1;

    /// @dev All roles related to accessing this contract
    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');

    // ----------------------------------------
    //      Events
    // ----------------------------------------

    event ProjectMinted(address receiver, uint256 tokenId);
    event ProjectUpdated(uint256 tokenId);
    event ProjectIdUpdated(uint256 tokenId);
    event BeneficiaryUpdated(uint256 indexed tokenId, address oldBeneficiary, address newBeneficiary);

    // ----------------------------------------
    //      Upgradable related functions
    // ----------------------------------------
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() external virtual initializer {
        __Context_init_unchained();
        __ERC721_init_unchained('Kyklos', 'Kyklos-project');
        __Ownable_init_unchained(msg.sender);
        __Pausable_init_unchained();
        __AccessControl_init_unchained();
        __UUPSUpgradeable_init_unchained();

        /// @dev granting the deployer==owner the rights to grant other roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // ----------------------------------------
    //      Internal functions
    // ----------------------------------------
    function setToucanContractRegistry(address _address) external virtual onlyOwner {
        contractRegistry = _address;
    }

    /// @notice Adds a new carbon project along with attributes/data
    /// @dev Projects can be added by data-managers (onlyManagers)
    function addNewProject(
        address to,
        string memory projectId,
        string memory standard,
        string memory methodology,
        string memory region,
        string memory storageMethod,
        string memory method,
        string memory emissionType,
        string memory category,
        string memory uri,
        address beneficiary
    ) external virtual override whenNotPaused returns (uint256) {
        require(!projectId.equals(''), 'ProjectId cannot be empty');
        require(!projectIds[projectId], 'Project already exists');
        projectIds[projectId] = true;

        uint256 newItemId = projectTokenCounter;
        unchecked {
            ++newItemId;
            ++totalSupply;
        }
        projectTokenCounter = uint128(newItemId);

        validProjectTokenIds[newItemId] = true;

        _mint(to, newItemId);

        projectData[newItemId].projectId = projectId;
        projectData[newItemId].standard = standard;
        projectData[newItemId].methodology = methodology;
        projectData[newItemId].region = region;
        projectData[newItemId].storageMethod = storageMethod;
        projectData[newItemId].method = method;
        projectData[newItemId].emissionType = emissionType;
        projectData[newItemId].category = category;
        projectData[newItemId].uri = uri;
        projectData[newItemId].beneficiary = beneficiary;

        emit ProjectMinted(to, newItemId);
        pidToTokenId[projectId] = newItemId;
        return newItemId;
    }

    /// @notice Updates and existing carbon project
    /// @dev Projects can be updated by data-managers
    function updateProject(
        uint256 tokenId,
        string memory newStandard,
        string memory newMethodology,
        string memory newRegion,
        string memory newStorageMethod,
        string memory newMethod,
        string memory newEmissionType,
        string memory newCategory,
        string memory newUri,
        address beneficiary
    ) external virtual whenNotPaused {
        require(_ownerOf(tokenId) != address(0), 'Project not yet minted');
        projectData[tokenId].standard = newStandard;
        projectData[tokenId].methodology = newMethodology;
        projectData[tokenId].region = newRegion;
        projectData[tokenId].storageMethod = newStorageMethod;
        projectData[tokenId].method = newMethod;
        projectData[tokenId].emissionType = newEmissionType;
        projectData[tokenId].category = newCategory;
        projectData[tokenId].uri = newUri;
        projectData[tokenId].beneficiary = beneficiary;

        emit ProjectUpdated(tokenId);
    }

    function isValidProjectTokenId(uint256 projectTokenId) external view virtual override returns (bool) {
        return validProjectTokenIds[projectTokenId];
    }

    /// @dev retrieve all data from ProjectData struct
    function getProjectDataByTokenId(uint256 tokenId) external view virtual override returns (ProjectData memory) {
        return (projectData[tokenId]);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControlUpgradeable, ERC721Upgradeable, IERC165) returns (bool) {
        return
            interfaceId == type(IAccessControlUpgradeable).interfaceId ||
            ERC721Upgradeable.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override {}
}

// import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';

// /// @notice The CarbonProjects contract stores carbon project-specific data
// /// The data is stored in structs via ERC721 tokens
// /// Most contracts in the protocol query the data stored here
// /// The attributes in the Project-NFTs are constant over all vintages of the project
// /// @dev Each project can have up to n vintages, with data stored in the
// /// `CarbonProjectVintages` contract. `vintageTokenId`s are mapped to `projectTokenId`s
// /// via `pvToTokenId` in the vintage contract.
// contract CarbonProjects is
//     ICarbonProjects,
//     CarbonProjectsStorage,
//     OwnableUpgradeable,
//     PausableUpgradeable,
//     Modifiers,
//     AccessControlUpgradeable,
//     UUPSUpgradeable
// {
//     using Strings for string;

//     // ------------------------
//     //      Admin functions
//     // ------------------------
//     /// @dev modifier that only lets the contract's owner and elected managers add/update/remove project data
//     modifier onlyManagers() {
//         require(
//             hasRole(MANAGER_ROLE, msg.sender) || owner() == msg.sender,
//             'Caller is not authorized'
//         );
//         _;
//     }

//     /// @notice Emergency function to disable contract's core functionality
//     /// @dev wraps _pause(), only Admin
//     function pause() external virtual onlyBy(contractRegistry, owner()) {
//         _pause();
//     }

//     /// @dev unpause the system, wraps _unpause(), only Admin
//     function unpause() external virtual onlyBy(contractRegistry, owner()) {
//         _unpause();
//     }

//     /// @notice Updates and existing carbon project
//     /// @dev Projects can be updated by data-managers
//     function updateProject(
//         uint256 tokenId,
//         string memory newStandard,
//         string memory newMethodology,
//         string memory newRegion,
//         string memory newStorageMethod,
//         string memory newMethod,
//         string memory newEmissionType,
//         string memory newCategory,
//         string memory newUri,
//         address beneficiary
//     ) external virtual onlyManagers whenNotPaused {
//         require(_exists(tokenId), 'Project not yet minted');
//         projectData[tokenId].standard = newStandard;
//         projectData[tokenId].methodology = newMethodology;
//         projectData[tokenId].region = newRegion;
//         projectData[tokenId].storageMethod = newStorageMethod;
//         projectData[tokenId].method = newMethod;
//         projectData[tokenId].emissionType = newEmissionType;
//         projectData[tokenId].category = newCategory;
//         projectData[tokenId].uri = newUri;
//         projectData[tokenId].beneficiary = beneficiary;

//         emit ProjectUpdated(tokenId);
//     }

//     /// @dev Projects and their projectId's must be unique, changing them must be handled carefully
//     function updateProjectId(uint256 tokenId, string memory newProjectId)
//         external
//         virtual
//         onlyManagers
//         whenNotPaused
//     {
//         require(_exists(tokenId), 'Project not yet minted');
//         if (bytes(newProjectId).length != 0) {
//             require(
//                 projectIds[newProjectId] == false,
//                 'Cant change current projectId to an existing one'
//             );
//         }

//         string memory oldProjectId = projectData[tokenId].projectId;
//         projectIds[oldProjectId] = false;

//         projectData[tokenId].projectId = newProjectId;
//         projectIds[newProjectId] = true;

//         emit ProjectIdUpdated(tokenId);
//     }

//     /// @notice Updates the project beneficiary
//     function updateBeneficiary(uint256 tokenId, address beneficiary)
//         external
//         virtual
//         onlyManagers
//         whenNotPaused
//     {
//         require(_exists(tokenId), 'Project not yet minted');
//         address oldBeneficiary = projectData[tokenId].beneficiary;
//         projectData[tokenId].beneficiary = beneficiary;
//         emit BeneficiaryUpdated(tokenId, oldBeneficiary, beneficiary);
//     }

//     /// @dev Removes a project and corresponding data, sets projectTokenId invalid
//     function removeProject(uint256 projectTokenId)
//         external
//         virtual
//         onlyManagers
//         whenNotPaused
//     {
//         delete projectData[projectTokenId];
//         /// @dev set projectTokenId to invalid
//         totalSupply--;
//         validProjectTokenIds[projectTokenId] = false;
//     }

//     function _baseURI() internal view virtual override returns (string memory) {
//         return baseURI;
//     }

//     function setBaseURI(string memory gateway) external virtual onlyOwner {
//         baseURI = gateway;
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

//         string memory uri = projectData[tokenId].uri;
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
