// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import './interfaces/ICarbonProjects.sol';
import './interfaces/IProjectVintages.sol';
import './interfaces/IPausable.sol';
// import './interfaces/ICarbonOffsetFactory.sol';

import './types/CarbonProjectTypes.sol';
import './storages/CarbonOffsetStorage.sol';
import './interfaces/IRegistry.sol';
import './interfaces/ICarbonTokenizer.sol';

// import '../CarbonOffsetBatchesTypes.sol';
// import '../interfaces/IRetirementCertificates.sol';
// import '../interfaces/IToucanCarbonOffsetsEscrow.sol';

contract CarbonOffsetToken is ERC20Upgradeable, CarbonOffsetsStorage, IERC721Receiver, Context {
    // ----------------------------------------
    //              Constants
    // ----------------------------------------
    /// @dev All roles related to accessing this contract
    bytes32 public constant DETOKENIZER_ROLE = keccak256('DETOKENIZER_ROLE');
    bytes32 public constant TOKENIZER_ROLE = keccak256('TOKENIZER_ROLE');
    bytes32 public constant RETIREMENT_ROLE = keccak256('RETIREMENT_ROLE');
    // ----------------------------------------
    //      Events
    // ----------------------------------------
    event FeePaid(address bridger, uint256 fees);
    event FeeBurnt(address bridger, uint256 fees);
    event Retired(address sender, uint256 amount, uint256 eventId);

    // ----------------------------------------
    //              Modifiers
    // ----------------------------------------

    /// @dev modifier checks whether the `ToucanCarbonOffsetsFactory` is paused
    /// Since TCO2 contracts are permissionless, pausing does not function individually
    modifier whenNotPaused() {
        // address tco2Factory = IRegistry(contractRegistry).toucanCarbonOffsetsFactoryAddress(standardRegistry());
        // bool _paused = IPausable(tco2Factory).paused();
        // require(!_paused, 'Paused TCO2');
        _;
    }
    modifier onlyFactoryOwner() {
        // address tco2Factory = ItRegistry(contractRegistry).CarbonOffsetsFactoryAddress(standardRegistry());
        // address owner = IToucanCarbonOffsetsFactory(tco2Factory).owner();
        // require(owner == msg.sender, 'Not factory owner');
        _;
    }
    /// @dev Modifier to disallowing sending tokens to either the 0-address
    /// or this contract itself
    modifier validDestination(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 projectVintageTokenId_,
        address contractRegistry_
    ) external virtual initializer {
        __ERC20_init_unchained(name_, symbol_);
        // _projectVintageTokenId = projectVintageTokenId_;
        contractRegistry = contractRegistry_;
    }

    // ----------------------------------------
    //       Permissioned functions
    // ----------------------------------------
    /// @dev Function to get corresponding attributes from the CarbonProjects
    function getAttributes() public view virtual returns (ProjectData memory, VintageData memory) {
        address pc = IRegistry(contractRegistry).carbonProjectsAddress();
        address vc = IRegistry(contractRegistry).carbonProjectVintagesAddress();
        address ct = IRegistry(contractRegistry).carbonTokenizerAddress();
        uint256 _projectVintageTokenId = ICarbonTokenizer(ct)
            .getVintageTokenIdByTokenId(_carbonTokenizerId)
            .projectVintageId;
        VintageData memory vintageData = IProjectVintages(vc).getProjectVintageDataByTokenId(_projectVintageTokenId);
        ProjectData memory projectData = ICarbonProjects(pc).getProjectDataByTokenId(vintageData.projectTokenId);

        return (projectData, vintageData);
    }

    /// @dev Helper function to retrieve data fragments for `name()` and `symbol()`
    function getGlobalProjectVintageIdentifiers() public view virtual returns (string memory, string memory) {
        ProjectData memory projectData;
        VintageData memory vintageData;
        (projectData, vintageData) = getAttributes();
        return (projectData.projectId, vintageData.name);
    }

    // ----------------------------------------
    //       Permissionless functions
    // ----------------------------------------

    function projectVintageTokenId() external view returns (uint256) {
        return _carbonTokenizerId;
    }

    /// @notice Token name getter overriden to return the a name based on the carbon project data
    //slither-disable-next-line external-function
    function name() public view virtual override returns (string memory) {
        string memory globalProjectId;
        string memory vintageName;
        (globalProjectId, vintageName) = getGlobalProjectVintageIdentifiers();
        return string(abi.encodePacked('Kyklos KCT:', globalProjectId, '-', vintageName));
    }

    /// @notice Token symbol getter overriden to return the a symbol based on the carbon project data
    //slither-disable-next-line external-function
    function symbol() public view virtual override returns (string memory) {
        string memory globalProjectId;
        string memory vintageName;
        (globalProjectId, vintageName) = getGlobalProjectVintageIdentifiers();
        return string(abi.encodePacked('KCT', globalProjectId, '-', vintageName));
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override validDestination(recipient) whenNotPaused returns (bool) {
        super.transfer(recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override validDestination(recipient) whenNotPaused returns (bool) {
        super.transferFrom(sender, recipient, amount);
        return true;
    }

    function _msgSender() internal view virtual override(Context, ContextUpgradeable) returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual override(Context, ContextUpgradeable) returns (bytes calldata) {
        return msg.data;
    }

    /// @notice Receive hook to fractionalize Batch-NFTs into ERC20's
    /// @dev Function is called with `operator` as `msg.sender` in a reference implementation by OZ
    /// `from` is the previous owner, not necessarily the same as operator.
    /// The hook checks if NFT collection is whitelisted and next if attributes are matching this ERC20 contract
    function onERC721Received(
        address /* operator */,
        address from,
        uint256 tokenId,
        bytes calldata /* data */
    ) external virtual override whenNotPaused returns (bytes4) {
        // msg.sender is the CarbonOffsetBatches contract

        // (
        //     uint256 gotVintageTokenId,
        //     uint256 quantity,
        //     BatchStatus status
        // ) = _getNormalizedDataFromBatch(msg.sender, tokenId);
        // require(
        //     gotVintageTokenId == _projectVintageTokenId,
        //     Errors.TCO2_NON_MATCHING_NFT
        // );
        // require(
        //     status == BatchStatus.Confirmed,
        //     Errors.TCO2_BATCH_NOT_CONFIRMED
        // );
        // require(getRemaining() >= quantity, Errors.TCO2_QTY_HIGHER);

        // minterToId[from] = tokenId;
        // IToucanCarbonOffsetsFactory tco2Factory = IToucanCarbonOffsetsFactory(
        //     IToucanContractRegistry(contractRegistry)
        //         .toucanCarbonOffsetsFactoryAddress(standardRegistry())
        // );
        // address bridgeFeeReceiver = tco2Factory.bridgeFeeReceiverAddress();

        // if (bridgeFeeReceiver == address(0x0)) {
        //     // @dev if no bridge fee receiver address is set, mint without fees
        //     _mint(from, quantity);
        // } else {
        //     // @dev calculate bridge fees
        //     (uint256 feeAmount, uint256 feeBurnAmount) = tco2Factory
        //         .getBridgeFeeAndBurnAmount(quantity);
        //     _mint(from, quantity - feeAmount);
        //     address bridgeFeeBurnAddress = tco2Factory.bridgeFeeBurnAddress();
        //     if (bridgeFeeBurnAddress != address(0x0) && feeBurnAmount > 0) {
        //         feeAmount -= feeBurnAmount;
        //         _mint(bridgeFeeReceiver, feeAmount);
        //         _mint(bridgeFeeBurnAddress, feeBurnAmount);
        //         emit FeePaid(from, feeAmount);
        //         emit FeeBurnt(from, feeBurnAmount);
        //     } else if (feeAmount > 0) {
        //         _mint(bridgeFeeReceiver, feeAmount);
        //         emit FeePaid(from, feeAmount);
        //     }
        // }

        return this.onERC721Received.selector;
    }
}

//     // Modifier that checks if msg.sender is the escrow contract
//     modifier onlyEscrow() {
//         require(
//             IRegistry(contractRegistry).toucanCarbonOffsetsEscrowAddress() == msg.sender,
//             'Not escrow contract'
//         );
//         _;
//     }

//     // ----------------------------------------
//     //      Bridge-related functions
//     // ----------------------------------------

//     /// @notice Burn TCO2 on behalf of a user. msg.sender does not require approval
//     /// by the account for the burn to be successfull. This function is exposed so it
//     /// can be utilized in cross-chain transfers of TCO2 where we want to burn the
//     /// TCO2 in the source chain but not retire it.
//     /// @param account The user for whom to burn TCO2
//     /// @param amount The amount to burn.
//     function bridgeBurn(address account, uint256 amount) external virtual whenNotPaused onlyBridges {
//         _burn(account, amount);
//     }

//     /// @notice Mint TCO2 on behalf of a user. This function is exposed to
//     /// be called by authorized message bridge systems and utilized for
//     /// cross-chain transfers of TCO2 where we want to mint the TCO2 in the
//     /// source chain.
//     /// @param account The user for whom to mint TCO2
//     /// @param amount The amount to mint.
//     function bridgeMint(address account, uint256 amount) external virtual whenNotPaused onlyBridges {
//         _mint(account, amount);
//     }

//     /// @dev Returns the remaining space in TCO2 contract before hitting the cap
//     function getRemaining() public view returns (uint256 remaining) {
//         uint256 cap = getDepositCap();
//         remaining = cap - totalSupply();
//     }

//     /// @dev Returns the cap for TCO2s based on `totalVintageQuantity`
//     /// Returns `~unlimited` if the value for the vintage is not set
//     function getDepositCap() public view returns (uint256) {
//         VintageData memory vintageData;
//         (, vintageData) = getAttributes();
//         uint64 totalVintageQuantity = vintageData.totalVintageQuantity;

//         ///@dev multipliying tonnes with decimals
//         uint256 cap = totalVintageQuantity * 10 ** decimals();

//         /// @dev if totalVintageQuantity is not set (=0), remove cap
//         if (cap == 0) return type(uint256).max;

//         return cap;
//     }

//     /// @notice Burn TCO2 on behalf of a user. msg.sender needs to be approved by
//     /// the account for the burn to be successfull. This function is exposed so it
//     /// can be utilized to burn credits without retiring them (eg. dispose HFC-23).
//     /// @param account The user for whom to burn TCO2
//     /// @param amount The amount to burn
//     function burnFrom(address account, uint256 amount) external virtual whenNotPaused {
//         _spendAllowance(account, msg.sender, amount);
//         _burn(account, amount);
//     }

//     // @dev Internal function for the burning of TCO2 tokens
//     // @dev retiringEntityAddress is a parameter to handle scenarios, when
//     // retirements are performed from the escrow contract and the retiring entity
//     // is different than the account.
//     function _retire(
//         address account,
//         uint256 amount,
//         address retiringEntityAddress
//     ) internal virtual returns (uint256 retirementEventId) {
//         _burn(account, amount);

//         // Register retirement event in the certificates contract
//         address certAddr = IRegistry(contractRegistry).retirementCertificatesAddress();
//         retirementEventId = IRetirementCertificates(certAddr).registerEvent(
//             retiringEntityAddress,
//             _projectVintageTokenId,
//             amount,
//             false
//         );

//         emit Retired(retiringEntityAddress, amount, retirementEventId);
//     }

//     // @dev Internal function retire and mint certificates
//     function _retireAndMintCertificate(
//         address retiringEntity,
//         CreateRetirementRequestParams memory params
//     ) internal virtual whenNotPaused {
//         // Retire provided amount
//         uint256 retirementEventId = _retire(msg.sender, params.amount, retiringEntity);
//         uint256[] memory retirementEventIds = new uint256[](1);
//         retirementEventIds[0] = retirementEventId;

//         //slither-disable-next-line unused-return
//         IRetirementCertificates(IRegistry(contractRegistry).retirementCertificatesAddress())
//             .mintCertificateWithExtraData(retiringEntity, params, retirementEventIds);
//     }
// }

// /// @notice Base contract that can be reused between different TCO2
// /// implementations that need to work with batch NFTs
// abstract contract ToucanCarbonOffsetsWithBatchBase is
//     IERC721Receiver,
//     ToucanCarbonOffsetsBase
// {
//     // ----------------------------------------
//     //       Admin functions
//     // ----------------------------------------

//     /// @notice Defractionalize batch NFT by burning the amount
//     /// of TCO2 from the sender and transfer the batch NFT that
//     /// was selected to the sender.
//     /// The only valid sender currently is the TCO2 factory owner.
//     /// @param tokenId The batch NFT to defractionalize from the TCO2
//     function defractionalize(uint256 tokenId)
//         external
//         whenNotPaused
//         onlyFactoryOwner
//     {
//         address batchNFT = IToucanContractRegistry(contractRegistry)
//             .carbonOffsetBatchesAddress();

//         // Fetch and burn amount of the NFT to be defractionalized
//         (
//             ,
//             uint256 batchAmount,
//             BatchStatus status
//         ) = _getNormalizedDataFromBatch(batchNFT, tokenId);
//         require(
//             status == BatchStatus.Confirmed,
//             Errors.TCO2_BATCH_NOT_CONFIRMED
//         );
//         _burn(msg.sender, batchAmount);

//         // Transfer batch NFT to sender
//         IERC721(batchNFT).transferFrom(address(this), msg.sender, tokenId);
//     }

//     /// @notice Receive hook to fractionalize Batch-NFTs into ERC20's
//     /// @dev Function is called with `operator` as `msg.sender` in a reference implementation by OZ
//     /// `from` is the previous owner, not necessarily the same as operator.
//     /// The hook checks if NFT collection is whitelisted and next if attributes are matching this ERC20 contract
//     function onERC721Received(
//         address, /* operator */
//         address from,
//         uint256 tokenId,
//         bytes calldata /* data */
//     ) external virtual override whenNotPaused returns (bytes4) {
//         // msg.sender is the CarbonOffsetBatches contract
//         require(
//             checkWhiteListed(msg.sender),
//             Errors.TCO2_BATCH_NOT_WHITELISTED
//         );

//         (
//             uint256 gotVintageTokenId,
//             uint256 quantity,
//             BatchStatus status
//         ) = _getNormalizedDataFromBatch(msg.sender, tokenId);
//         require(
//             gotVintageTokenId == _projectVintageTokenId,
//             Errors.TCO2_NON_MATCHING_NFT
//         );
//         require(
//             status == BatchStatus.Confirmed,
//             Errors.TCO2_BATCH_NOT_CONFIRMED
//         );
//         require(getRemaining() >= quantity, Errors.TCO2_QTY_HIGHER);

//         minterToId[from] = tokenId;
//         IToucanCarbonOffsetsFactory tco2Factory = IToucanCarbonOffsetsFactory(
//             IToucanContractRegistry(contractRegistry)
//                 .toucanCarbonOffsetsFactoryAddress(standardRegistry())
//         );
//         address bridgeFeeReceiver = tco2Factory.bridgeFeeReceiverAddress();

//         if (bridgeFeeReceiver == address(0x0)) {
//             // @dev if no bridge fee receiver address is set, mint without fees
//             _mint(from, quantity);
//         } else {
//             // @dev calculate bridge fees
//             (uint256 feeAmount, uint256 feeBurnAmount) = tco2Factory
//                 .getBridgeFeeAndBurnAmount(quantity);
//             _mint(from, quantity - feeAmount);
//             address bridgeFeeBurnAddress = tco2Factory.bridgeFeeBurnAddress();
//             if (bridgeFeeBurnAddress != address(0x0) && feeBurnAmount > 0) {
//                 feeAmount -= feeBurnAmount;
//                 _mint(bridgeFeeReceiver, feeAmount);
//                 _mint(bridgeFeeBurnAddress, feeBurnAmount);
//                 emit FeePaid(from, feeAmount);
//                 emit FeeBurnt(from, feeBurnAmount);
//             } else if (feeAmount > 0) {
//                 _mint(bridgeFeeReceiver, feeAmount);
//                 emit FeePaid(from, feeAmount);
//             }
//         }

//         return this.onERC721Received.selector;
//     }

//     // ----------------------------------------
//     //       Internal functions
//     // ----------------------------------------

//     function _getNormalizedDataFromBatch(address cob, uint256 tokenId)
//         internal
//         view
//         returns (
//             uint256,
//             uint256,
//             BatchStatus
//         )
//     {
//         (
//             uint256 vintageTokenId,
//             uint256 quantity,
//             BatchStatus status
//         ) = ICarbonOffsetBatches(cob).getBatchNFTData(tokenId);
//         return (vintageTokenId, quantity * 10**decimals(), status);
//     }

//     /// @dev Internal helper to check if CarbonOffsetBatches is whitelisted (official)
//     function checkWhiteListed(address collection)
//         internal
//         view
//         virtual
//         returns (bool)
//     {
//         if (
//             collection ==
//             IToucanContractRegistry(contractRegistry)
//                 .carbonOffsetBatchesAddress()
//         ) {
//             return true;
//         } else {
//             return false;
//         }
//     }
// }
