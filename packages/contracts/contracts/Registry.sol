// // SPDX-FileCopyrightText: UNLICENSED
// //
// // SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';

import './interfaces/IRegistry.sol';
import './storages/RegistryStorage.sol';
import './interfaces/IPausable.sol';

contract Registry is IRegistry, RegistryStorage, OwnableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    // ----------------------------------------
    //      constants
    // ----------------------------------------
    string public constant VERSION = '1.0';
    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');

    // ----------------------------------------
    //      Events
    // ----------------------------------------

    event TCO2FactoryAdded(address indexed factory, string indexed standard);

    // ----------------------------------------
    //      Modifiers
    // ----------------------------------------

    modifier onlyBy(address _factory, address _owner) {
        require(_factory == msg.sender || _owner == msg.sender, 'Caller is not the factory');
        _;
    }

    /// @dev modifier that only lets the contract's owner and granted pausers pause the system
    modifier onlyPausers() {
        require(hasRole(PAUSER_ROLE, msg.sender) || owner() == msg.sender, 'Caller is not authorized');
        _;
    }

    // ----------------------------------------
    //      Constructor
    // ----------------------------------------
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() external virtual initializer {
        __AccessControl_init_unchained();
        __UUPSUpgradeable_init_unchained();
        __Ownable_init(msg.sender);

        /// @dev granting the deployer==owner the rights to grant other roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    // ----------------------------------------
    //      Internal functions
    // ----------------------------------------
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

    // ----------------------------------------
    //      setter
    // ----------------------------------------
    function setCarbonProjectsAddress(address _address) external virtual onlyOwner {
        require(_address != address(0), 'Zero address');
        _carbonProjectsAddress = _address;
    }

    function setCarbonProjectVintagesAddress(address _address) external virtual onlyOwner {
        require(_address != address(0), 'Zero address');
        _carbonProjectVintagesAddress = _address;
    }

    function setCarbonTokenizerAddress(address _address) external virtual onlyOwner {
        require(_address != address(0), 'Zero address');
        _carbonTokenizerAddress = _address;
    }

    function setCarbonOffsetTokenAddress(address _address) external virtual onlyOwner {
        require(_address != address(0), 'Zero address');
        _carbonOffsetTokenAddress = _address;
    }

    function setCarbonOffsetTokenFactoryAddress(address _address) external virtual onlyOwner {
        require(_address != address(0), 'Zero address');
        _carbonOffsetTokenFactoryAddress = _address;
    }

    function setRetirementCertificatesAddress(address _address) external virtual onlyOwner {
        require(_address != address(0), 'Zero address');
        _retirementCertificatesAddress = _address;
    }

    // ----------------------------------------
    //      getter
    // ----------------------------------------
    function carbonProjectsAddress() external view override returns (address) {
        return _carbonProjectsAddress;
    }

    function carbonProjectVintagesAddress() external view override returns (address) {
        return _carbonProjectVintagesAddress;
    }

    function carbonTokenizerAddress() external view override returns (address) {
        return _carbonTokenizerAddress;
    }

    function carbonOffsetTokenAddress() external view override returns (address) {
        return _carbonOffsetTokenAddress;
    }

    function carbonOffsetTokenFactoryAddress() external view override returns (address) {
        return _carbonOffsetTokenFactoryAddress;
    }

    function retirementCertificatesAddress() external view override returns (address) {
        return _retirementCertificatesAddress;
    }

    // ----------------------------------------
    //      Pausing
    // ----------------------------------------
    //     /// @notice security function that pauses all contracts part of the carbon bridge
    function pauseSystem() external onlyPausers {
        IPausable cpv = IPausable(_carbonProjectVintagesAddress);
        if (!cpv.paused()) cpv.pause();

        IPausable cp = IPausable(_carbonProjectsAddress);
        if (!cp.paused()) cp.pause();

        IPausable cob = IPausable(_carbonOffsetTokenAddress);
        if (!cob.paused()) cob.pause();
    }

    /// @notice security function that unpauses all contracts part of the carbon bridge
    function unpauseSystem() external onlyOwner {
        IPausable cpv = IPausable(_carbonProjectVintagesAddress);
        if (cpv.paused()) cpv.unpause();

        IPausable cp = IPausable(_carbonProjectsAddress);
        if (cp.paused()) cp.unpause();

        IPausable cob = IPausable(_carbonOffsetTokenAddress);
        if (cob.paused()) cob.unpause();
    }

    // adding only protection
    function addERC20(address erc20) external virtual {
        projectVintageERC20Registry[erc20] = true;
    }
}

// import './interfaces/IPausable.sol';
// import './interfaces/IToucanCarbonOffsetsFactory.sol';
// import './libraries/Strings.sol';

// /// @dev The ToucanContractRegistry is queried by other contracts for current addresses
// contract ToucanContractRegistry is
//     ToucanContractRegistryStorageLegacy,
//     UUPSUpgradeable,
// {
//     // ----------------------------------------
//     //      Constants
//     // ----------------------------------------

//     /// @dev Version-related parameters. VERSION keeps track of production
//     /// releases. VERSION_RELEASE_CANDIDATE keeps track of iterations
//     /// of a VERSION in our staging environment.
//     string public constant VERSION = '1.2.0';
//     uint256 public constant VERSION_RELEASE_CANDIDATE = 1;

//     /// @dev All roles related to accessing this contract

//     // ----------------------------------------
//     //      Events
//     // ----------------------------------------

//     event TCO2FactoryAdded(address indexed factory, string indexed standard);

//     /// @custom:oz-upgrades-unsafe-allow constructor
//     constructor() {
//         _disableInitializers();
//     }

//     // ----------------------------------------
//     //              Setters
//     // ----------------------------------------

//     function setToucanCarbonOffsetsFactoryAddress(address tco2Factory)
//         external
//         virtual
//         onlyOwner
//     {
//         require(tco2Factory != address(0), 'Zero address');

//         // Get the standard registry from the factory
//         string memory standardRegistry = IToucanCarbonOffsetsFactory(
//             tco2Factory
//         ).standardRegistry();
//         require(bytes(standardRegistry).length != 0, 'Empty standard registry');

//         if (!standardRegistryExists(standardRegistry)) {
//             standardRegistries.push(standardRegistry);
//         }
//         toucanCarbonOffsetFactories[standardRegistry] = tco2Factory;

//         emit TCO2FactoryAdded(tco2Factory, standardRegistry);
//     }

//     /// Add valid TCO2 contracts for Verra
//     /// TODO: Kept for backwards-compatibility; will be removed in a future
//     /// upgrade in favor of addERC20(erc20, 'verra')

//     /// @notice Keep track of TCO2s per standard
//     function addERC20(address erc20, string calldata standardRegistry)
//         external
//         virtual
//         onlyBy(toucanCarbonOffsetFactories[standardRegistry], owner())
//     {
//         projectVintageERC20Registry[erc20] = true;
//     }

//     // ----------------------------------------
//     //              Getters
//     // ----------------------------------------

//     /// Returns the TCO2 factory for Verra
//     /// TODO: Kept for backwards-compatibility; will be removed in a future
//     /// upgrade in favor of toucanCarbonOffsetsFactory('verra')
//     function toucanCarbonOffsetsFactoryAddress()
//         external
//         view
//         virtual
//         override
//         returns (address)
//     {
//         return DEPRECATED_toucanCarbonOffsetsFactoryAddress;
//     }

//     /// @dev return the TCO2 factory address for the provided standard
//     function toucanCarbonOffsetsFactoryAddress(string memory standardRegistry)
//         external
//         view
//         virtual
//         override
//         returns (address)
//     {
//         return toucanCarbonOffsetFactories[standardRegistry];
//     }

//     function toucanCarbonOffsetsEscrowAddress()
//         external
//         view
//         virtual
//         override
//         returns (address)
//     {
//         return _toucanCarbonOffsetsEscrowAddress;
//     }

//     /// TODO: Remove in a future upgrade now that we have retirementCertificatesAddress
//     function carbonOffsetBadgesAddress()
//         external
//         view
//         virtual
//         returns (address)
//     {
//         return _retirementCertificatesAddress;
//     }

//     /// TODO: Kept for backwards-compatibility; will be removed in a future
//     /// upgrade in favor of isValidERC20(erc20)
//     function checkERC20(address erc20) external view virtual returns (bool) {
//         return projectVintageERC20Registry[erc20];
//     }

//     function isValidERC20(address erc20)
//         external
//         view
//         virtual
//         override
//         returns (bool)
//     {
//         return projectVintageERC20Registry[erc20];
//     }
