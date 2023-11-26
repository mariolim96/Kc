// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol';

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

import './libraries/Strings.sol';
import './libraries/Modifiers.sol';
import './interfaces/IRegistry.sol';
import './interfaces/ICarbonProjects.sol';
import './interfaces/IProjectVintages.sol';
import './libraries/ProjectUtils.sol';
import './libraries/ProjectVintageUtils.sol';
import './storages/CarbonOffsetFactoryStorage.sol';
import './interfaces/ICarbonTokenizer.sol';
import './interfaces/IPausable.sol';

import './interfaces/ICarbonOffsetFactory.sol';

contract CarbonOffsetFactory is
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    CarbonOffsetFactoryStorage,
    Modifiers,
    ProjectVintageUtils,
    ICarbonOffsetsFactory
{
    // ----------------------------------------
    //      Constants
    // ----------------------------------------
    /// @dev divider to calculate fees in basis points
    uint256 public constant bridgeFeeDivider = 1e4;
    /// @dev All roles related to accessing this contract
    bytes32 public constant DETOKENIZER_ROLE = keccak256('DETOKENIZER_ROLE');
    bytes32 public constant TOKENIZER_ROLE = keccak256('TOKENIZER_ROLE');
    using StringsLib for string;
    // ----------------------------------------
    //      Events
    // ----------------------------------------
    event TokenCreated(uint256 vintageTokenId, address tokenAddress);

    // ----------------------------------------
    //      Constructor and init functions
    // ----------------------------------------
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function inizialize(address[] calldata accounts, bytes32[] calldata roles) external virtual initializer {
        require(accounts.length == roles.length, 'Array length mismatch');

        __Context_init_unchained();
        __Ownable_init_unchained(msg.sender);
        __Pausable_init_unchained();
        __UUPSUpgradeable_init_unchained();
        __AccessControl_init_unchained();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // bool hasDefaultAdmin = false;
        for (uint256 i = 0; i < accounts.length; ++i) {
            _grantRole(roles[i], accounts[i]);
            // if (roles[i] == DEFAULT_ADMIN_ROLE) hasDefaultAdmin = true;
        }
        // require(hasDefaultAdmin, 'No admin specified');
    }

    /// @dev sets the Beacon that tracks the current implementation logic of the TCO2s
    function setBeacon(address _beacon) external virtual onlyOwner {
        beacon = _beacon;
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

    function setRegistry(address _address) external virtual onlyOwner {
        contractRegistry = _address;
    }

    function pvIdtoERC20(uint256 pvId) external view override returns (address) {
        return _pvIdtoERC20[pvId];
    }

    function owner() public view override(ICarbonOffsetsFactory, OwnableUpgradeable) returns (address) {
        return super.owner();
    }

    /// @notice internal factory function to deploy new TCO2 (ERC20) contracts
    /// @dev the function creates a new BeaconProxy for each TCO2
    /// @param projectVintageTokenId links the vintage-specific data to the TCO2 contract
    function deployNewProxy(uint256 projectVintageTokenId) internal virtual whenNotPaused {
        require(beacon != address(0), 'Error: Beacon for proxy not set');
        require(!checkExistence(projectVintageTokenId), 'pvERC20 already exists');
        checkProjectVintageTokenExists(contractRegistry, projectVintageTokenId);

        /// @dev generate payload for initialize function
        string memory signature = 'initialize(string,string,uint256,address)';
        bytes memory payload = abi.encodeWithSignature(
            signature,
            'Kyklos: KCO2',
            'KCO2',
            projectVintageTokenId,
            contractRegistry
        );

        //slither-disable-next-line reentrancy-no-eth
        BeaconProxy proxyTCO2 = new BeaconProxy(beacon, payload);

        IRegistry(contractRegistry).addERC20(address(proxyTCO2));

        deployedContracts.push(address(proxyTCO2));
        _pvIdtoERC20[projectVintageTokenId] = address(proxyTCO2);

        emit TokenCreated(projectVintageTokenId, address(proxyTCO2));
    }

    /// @dev Checks if same project vintage has already been deployed
    function checkExistence(uint256 projectVintageTokenId) internal view virtual returns (bool) {
        if (_pvIdtoERC20[projectVintageTokenId] == address(0)) {
            return false;
        } else {
            return true;
        }
    }

    /// @dev Returns all addresses of deployed TCO2 contracts
    function getContracts() external view virtual returns (address[] memory) {
        return deployedContracts;
    }

    /// @dev Deploys a TCO2 contract based on a project vintage
    /// @param projectVintageTokenId numeric tokenId from vintage in `CarbonProjectVintages`
    function deployFromVintage(uint256 projectVintageTokenId) external virtual whenNotPaused {
        deployNewProxy(projectVintageTokenId);
    }

    /// @notice Emergency function to disable contract's core functionality
    /// @dev wraps _pause(), only Admin
    function pause() external virtual onlyBy(contractRegistry, owner()) {
        _pause();
    }

    /// @dev unpause the system, wraps _unpause(), only Admin
    function unpause() external virtual onlyBy(contractRegistry, owner()) {
        _unpause();
    }

    function bridgeFeeReceiverAddress() external view virtual returns (address) {
        return bridgeFeeReceiver;
    }

    function getBridgeFeeAndBurnAmount(uint256 _quantity) external view virtual returns (uint256, uint256) {
        //slither-disable-next-line divide-before-multiply
        uint256 feeAmount = (_quantity * bridgeFeePercentageInBase) / bridgeFeeDivider;
        //slither-disable-next-line divide-before-multiply
        uint256 burnAmount = (feeAmount * bridgeFeeBurnPercentageInBase) / bridgeFeeDivider;
        return (feeAmount, burnAmount);
    }

    /// @notice Update the bridge fee percentage
    /// @param _bridgeFeePercentageInBase percentage of bridge fee in base
    function setBridgeFeePercentage(uint256 _bridgeFeePercentageInBase) external virtual onlyOwner {
        require(
            _bridgeFeePercentageInBase < bridgeFeeDivider,
            'bridge fee percentage must be lower than bridge fee divider'
        );
        bridgeFeePercentageInBase = _bridgeFeePercentageInBase;
    }

    /// @notice Update the bridge fee receiver
    /// @param _bridgeFeeReceiver address to transfer the fees
    function setBridgeFeeReceiver(address _bridgeFeeReceiver) external virtual onlyOwner {
        bridgeFeeReceiver = _bridgeFeeReceiver;
    }

    /// @notice Update the bridge fee burning percentage
    /// @param _bridgeFeeBurnPercentageInBase percentage of bridge fee in base
    function setBridgeFeeBurnPercentage(uint256 _bridgeFeeBurnPercentageInBase) external virtual onlyOwner {
        require(
            _bridgeFeeBurnPercentageInBase < bridgeFeeDivider,
            'burn fee percentage must be lower than bridge fee divider'
        );
        bridgeFeeBurnPercentageInBase = _bridgeFeeBurnPercentageInBase;
    }

    /// @notice Update the bridge fee burn address
    /// @param _bridgeFeeBurnAddress address to transfer the fees to burn
    function setBridgeFeeBurnAddress(address _bridgeFeeBurnAddress) external virtual onlyOwner {
        bridgeFeeBurnAddress = _bridgeFeeBurnAddress;
    }

    function getBridgeFeeBurnAddress() external view virtual returns (address) {
        return bridgeFeeBurnAddress;
    }
}
