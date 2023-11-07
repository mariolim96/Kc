// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.20;
import {VintageData} from './types/VintageData.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';

import './interfaces/IRegistry.sol';
import {IProjectVintages} from './interfaces/IProjectVintages.sol';
import './interfaces/ICarbonTokenizer.sol';
import './types/CarbonTokenizer.types.sol';

contract CarbonTokenizerContract is
    Initializable,
    ERC721Upgradeable,
    ERC721PausableUpgradeable,
    AccessControlUpgradeable,
    ERC721BurnableUpgradeable,
    UUPSUpgradeable,
    ICarbonTokenizer
{
    // ----------------------------------------
    //       constants
    // ----------------------------------------
    string public constant VERSION = '1.0';
    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 public constant UPGRADER_ROLE = keccak256('UPGRADER_ROLE');
    // ----------------------------------------
    //       storage
    // ----------------------------------------
    address public registryAddress;
    uint256 internal _projectVintageTokenizedCounter;

    // tokenizedId => vintageTokenId
    mapping(uint256 => batchTokenized) public projectVintageTokenized;
    // vintageTokenId => tokenizedId
    mapping(uint256 => uint256) public vintageTokenIdToTokenizedId;
    // ----------------------------------------
    //       Events
    // ----------------------------------------
    event ProjectVintageTokenizedEvent(uint256 projectVintageTokenId, uint256 tokenId, uint256 amount);

    // ----------------------------------------
    //       Constructor
    // ----------------------------------------
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address defaultAdmin, address pauser, address minter, address upgrader) public initializer {
        __ERC721_init('Kyklos-TKN', 'KTKN');
        __ERC721Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, pauser);
        _grantRole(MINTER_ROLE, minter);
        _grantRole(UPGRADER_ROLE, upgrader);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(address to) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _projectVintageTokenizedCounter++;
        _safeMint(to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    // The following functions are overrides required by Solidity.
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721Upgradeable, ERC721PausableUpgradeable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // ----------------------------------------
    //       Public functions
    // ----------------------------------------

    function fractionalize(uint256 vintageTokenId) public override {
        IRegistry registry = IRegistry(registryAddress);
        IProjectVintages projectVintages = IProjectVintages(registry.carbonProjectVintagesAddress());
        require(projectVintages.exists(vintageTokenId), 'vintageTokenId does not exist');
        VintageData memory vintageData = projectVintages.getProjectVintageDataByTokenId(vintageTokenId);
        batchTokenized memory batchTokenizedData = projectVintageTokenized[vintageTokenId];
        //verify if the batch of vitages Exists
        if (vintageTokenIdToTokenizedId[vintageTokenId] == 0) {
            //create the batch of vintages
            uint256 tokenId = _projectVintageTokenizedCounter++;
            _safeMint(msg.sender, tokenId);
            projectVintageTokenized[vintageTokenId] = batchTokenized(tokenId, Status.fractionalized);
            vintageTokenIdToTokenizedId[vintageTokenId] = tokenId;
            // we need to finish the minting of the ERC20 with the factory
            emit ProjectVintageTokenizedEvent(tokenId, vintageTokenId, vintageData.totalVintageQuantity);
        } else {
            require(
                batchTokenizedData.status == Status.fractionalized,
                'The batch of vintages is not in the fractionalized status'
            );
            // same here
        }
    }

    function setCarbonRegistryAddress(address _registryAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        registryAddress = _registryAddress;
    }

    function getCarbonRegistryAddress() public view returns (address) {
        return registryAddress;
    }

    function getVintageTokenIdByTokenId(uint256 tokenId) public view override returns (batchTokenized memory) {
        return projectVintageTokenized[tokenId];
    }

    function getTokenIdByVintageTokenId(uint256 vintageTokenId) public view returns (uint256) {
        return vintageTokenIdToTokenizedId[vintageTokenId];
    }
}
