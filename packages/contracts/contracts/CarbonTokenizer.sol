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
import './interfaces/ICarbonTokenizer.sol';
import './interfaces/IProjectVintages.sol';
import './types/CarbonTokenizer.types.sol';
import {ICarbonOffsetsFactory} from './interfaces/ICarbonOffsetFactor.sol';
import 'hardhat/console.sol';

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
    mapping(uint256 => batchTokenized) public projectVintageBatches;
    // vintageTokenId => tokenizedId
    mapping(uint256 => uint256) public vintageIdToTokenizedId;
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

    function safeMint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
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
    // function mintBatchTokenized(uint256 vintageTokenId) public {
    //     IRegistry registry = IRegistry(registryAddress);
    //     // create a new batch of vintage  with status active a

    // }
    function fractionalize(uint256 vintageTokenId) public override {
        IRegistry registry = IRegistry(registryAddress);
        IProjectVintages projectVintages = IProjectVintages(registry.carbonProjectVintagesAddress());
        require(projectVintages.exists(vintageTokenId), 'vintageTokenId does not exist');
        VintageData memory vintageData = projectVintages.getProjectVintageDataByTokenId(vintageTokenId);
        batchTokenized memory batchTokenizedData = projectVintageBatches[vintageTokenId];
        address tokenAddress = registry.carbonOffsetTokenFactoryAddress();
        ICarbonOffsetsFactory factoryy = ICarbonOffsetsFactory(registry.carbonOffsetTokenFactoryAddress());
        // verify if the batch of vitages Exists
        if (vintageIdToTokenizedId[vintageTokenId] == 0) {
            //create the batch of vintages
            uint256 tokenId = ++_projectVintageTokenizedCounter;
            _safeMint(msg.sender, tokenId);
            projectVintageBatches[vintageTokenId] = batchTokenized(
                tokenId,
                Status.fractionalized,
                vintageData.totalVintageQuantity
            );
            vintageIdToTokenizedId[vintageTokenId] = tokenId;
            console.log('vintageTokenId:', vintageTokenId);
            // we need to finish the minting of the ERC20 with the factory
            console.log('tokenAddress:', tokenAddress);
            factoryy.deployFromVintage(vintageTokenId);
            // TRANSFER THE TOKENS TO THE OWNER
            address tco2 = factoryy.pvIdtoERC20(vintageTokenId);
            safeTransferFrom(_msgSender(), tco2, tokenId, '');

            emit ProjectVintageTokenizedEvent(tokenId, vintageTokenId, vintageData.totalVintageQuantity);
            console.log('ProjectVintageTokenizedEvent', tokenId, vintageTokenId, vintageData.totalVintageQuantity);
        } else {
            require(
                batchTokenizedData.status == Status.active,
                'The batch of vintages is not in the fractionalized status'
            );
            uint256 tokenId = ++_projectVintageTokenizedCounter;

            // set status to fractionalized
            projectVintageBatches[vintageTokenId].status = Status.fractionalized;
            factoryy.deployFromVintage(vintageTokenId);
            address tco2 = factoryy.pvIdtoERC20(vintageTokenId);
            safeTransferFrom(_msgSender(), tco2, tokenId, '');
        }
    }

    function getVintageBatchByTokenId(uint256 tokenId) public view override returns (batchTokenized memory) {
        return projectVintageBatches[tokenId];
    }

    function getTokenIdByVintageTokenId(uint256 vintageTokenId) public view returns (uint256) {
        return vintageIdToTokenizedId[vintageTokenId];
    }

    function getVintageTokenIdByTokenId(uint256 tokenId) external view virtual override returns (uint256) {
        return projectVintageBatches[tokenId].projectVintageId;
    }

    function getVintageInfo(
        uint256 vintageTokenizedId
    ) public view override returns (uint256 vintageTokenId, uint256 amount, Status status) {
        batchTokenized memory batchTokenizedData = projectVintageBatches[vintageTokenizedId];
        return (batchTokenizedData.projectVintageId, batchTokenizedData.amount, batchTokenizedData.status);
    }

    function setCarbonRegistryAddress(address _registryAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        registryAddress = _registryAddress;
    }

    function getCarbonRegistryAddress() public view returns (address) {
        return registryAddress;
    }
}
