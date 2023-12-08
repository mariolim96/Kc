// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol';

// import './bases/ToucanCarbonOffsetsWithBatchBaseTypes.sol';
// import './interfaces/ICarbonProjectVintages.sol';
// import './interfaces/IToucanCarbonOffsets.sol';
import './interfaces/IRegistry.sol';
import './libraries/Strings.sol';
import './storages/RetirementsStorage.sol';
import {RetirementRequestParams} from './types/RetirementTypes.sol';

import {IRetirementCertificates} from './interfaces/IRetirements.sol';
import 'hardhat/console.sol';

/// @notice The `RetirementCertificates` contract lets users mint NFTs that act as proof-of-retirement.
/// These Retirement Certificate NFTs display how many TCO2s a user has burnt
/// @dev The amount of RetirementEvents is denominated in the 18-decimal form
/// @dev Getters in this contract return the corresponding amount in tonnes or kilos
contract RetirementCertificates is
    ERC721Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    RetirementCertificatesStorageV1,
    ReentrancyGuardUpgradeable,
    RetirementCertificatesStorage,
    IRetirementCertificates
{
    // ----------------------------------------
    //      Libraries
    // ----------------------------------------

    using Address for address;
    using Strings for string;
    // using Stringslib for string;

    // ----------------------------------------
    //      Constants
    // ----------------------------------------

    /// @dev Version-related parameters. VERSION keeps track of production
    /// releases. VERSION_RELEASE_CANDIDATE keeps track of iterations
    /// of a VERSION in our staging environment.
    string public constant VERSION = '1.1.0';
    uint256 public constant VERSION_RELEASE_CANDIDATE = 1;

    /// @dev dividers to round carbon in human-readable denominations
    uint256 public constant tonneDenomination = 1e18;
    uint256 public constant kiloDenomination = 1e15;

    // ----------------------------------------
    //      Events
    // ----------------------------------------

    event CertificateMinted(uint256 tokenId);
    event CertificateUpdated(uint256 tokenId);
    event BaseURISet(string baseURI);
    event MinValidAmountSet(uint256 previousAmount, uint256 newAmount);

    // event EventsAttached(uint256 tokenId, uint256[] eventIds);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ----------------------------------------
    //      Upgradable related functions
    // ----------------------------------------

    function initialize(address _contractRegistry, string memory _baseURI) external virtual initializer {
        __Context_init_unchained();
        __ERC721_init_unchained('Toucan Protocol: Retirement Certificates for Tokenized Carbon Offsets', 'TOUCAN-CERT');
        __Ownable_init_unchained(msg.sender);
        __ReentrancyGuard_init_unchained();
        __UUPSUpgradeable_init_unchained();

        contractRegistry = _contractRegistry;
        baseURI = _baseURI;
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

    // ------------------------
    //      Admin functions
    // ------------------------

    function setRegistry(address _address) external virtual onlyOwner {
        contractRegistry = _address;
    }

    function setBaseURI(string memory baseURI_) external virtual onlyOwner {
        baseURI = baseURI_;
        emit BaseURISet(baseURI_);
        console.log('baseURI', baseURI);
    }

    function setMinValidRetirementAmount(uint256 amount) external onlyOwner {
        uint256 previousAmount = minValidRetirementAmount;
        require(previousAmount != amount, 'Already set');

        minValidRetirementAmount = amount;
        emit MinValidAmountSet(previousAmount, amount);
        console.log('minValidRetirementAmount', minValidRetirementAmount);
    }

    // ----------------------------------
    //     Permissionless functions
    // ----------------------------------

    /// @notice Mint new Retirement Certificate NFT that shows how many TCO2s have been retired.
    /// @return The token id of the newly minted NFT.
    /// @dev    The function can either be called by a valid TCO2 contract or by someone who
    ///         owns retirement events.
    function mintCertificate(
        address retiringEntity,
        RetirementRequestParams memory params
    ) external virtual nonReentrant returns (uint256) {
        return _mintCertificate(retiringEntity, params);
    }

    function _mintCertificate(
        address retiringEntity,
        RetirementRequestParams memory params
    ) internal returns (uint256) {
        // If the provided retiring entity is not the caller, then
        // ensure the caller is at least a TCO2 contract. This is to
        // allow TCO2 contracts to call retireAndMintCertificate.
        require(
            retiringEntity == msg.sender || IRegistry(contractRegistry).isValidERC20(msg.sender) == true,
            'Invalid caller'
        );

        uint256 newItemId = _tokenIds;
        unchecked {
            ++newItemId;
        }
        _tokenIds = newItemId;

        retirements[newItemId].retiringEntity = retiringEntity;
        retirements[newItemId].beneficiary = params.beneficiary;
        retirements[newItemId].retiringEntityString = params.retiringEntityString;
        retirements[newItemId].beneficiaryString = params.beneficiaryString;
        retirements[newItemId].retirementMessage = params.retirementMessage;
        retirements[newItemId].amount = params.amount;
        retirements[newItemId].retiremenId = newItemId;
        retirements[newItemId].createdAt = block.timestamp;

        _safeMint(retiringEntity, newItemId);
        emit CertificateMinted(newItemId);
        console.log('CertificateMinted', newItemId);

        return newItemId;
    }

    /// @param tokenId The id of the NFT to get the URI.
    /// @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    /// based on the ERC721URIStorage implementation
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        // require(_exists(tokenId), 'ERC721URIStorage: URI query for nonexistent token');
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    /// @notice Update retirementMessage, beneficiary, and beneficiaryString of a NFT
    /// within 24h of creation. Empty values are ignored, ie., will not overwrite the
    /// existing stored values in the NFT.
    /// @param tokenId The id of the NFT to update.
    /// @param retiringEntityString An identifiable string for the retiring entity, eg. their name.
    /// @param beneficiary The new beneficiary to set in the NFT.
    /// @param beneficiaryString An identifiable string for the beneficiary, eg. their name.
    /// @param retirementMessage The new retirementMessage to set in the NFT.
    // function updateCertificate(
    //     uint256 tokenId,
    //     string calldata retiringEntityString,
    //     address beneficiary,
    //     string calldata beneficiaryString,
    //     string calldata retirementMessage
    // ) external virtual {
    //     string[] memory registries = new string[](1);
    //     registries[0] = 'verra';
    //     require(isCertificateForRegistry(tokenId, registries), 'Invalid registry');
    //     require(msg.sender == ownerOf(tokenId), 'Sender is not owner');
    //     require(block.timestamp < certificates[tokenId].createdAt + 24 hours, '24 hours elapsed');

    //     if (bytes(retiringEntityString).length != 0) {
    //         certificates[tokenId].retiringEntityString = retiringEntityString;
    //     }
    //     if (beneficiary != address(0)) {
    //         certificates[tokenId].beneficiary = beneficiary;
    //     }
    //     if (bytes(beneficiaryString).length != 0) {
    //         certificates[tokenId].beneficiaryString = beneficiaryString;
    //     }
    //     if (bytes(retirementMessage).length != 0) {
    //         certificates[tokenId].retirementMessage = retirementMessage;
    //     }

    //     emit CertificateUpdated(tokenId);
    // }

    /// @notice Get certificate data for an NFT.
    /// @param tokenId The id of the NFT to get data for.
    function getData(uint256 tokenId) external view returns (RetirementsData memory) {
        return retirements[tokenId];
    }

    /// @notice Get total retired amount for an NFT.
    /// @param tokenId The id of the NFT to update.
    /// @return amount Total retired amount for an NFT.
    /// @dev The return amount is denominated in 18 decimals, similar to amounts
    /// as they are read in TCO2 contracts.
    /// For example, 1000000000000000000 means 1 tonne.
    function getRetiredAmount(uint256 tokenId) external view returns (uint256 amount) {
        return retirements[tokenId].amount;
    }

    /// @notice Get total retired amount for an NFT in tonnes.
    /// @param tokenId The id of the NFT to update.
    /// @return amount Total retired amount for an NFT in tonnes.
    function getRetiredAmountInTonnes(uint256 tokenId) external view returns (uint256) {
        uint256 amount = retirements[tokenId].amount;
        return amount / tonneDenomination;
    }

    /// @notice Get total retired amount for an NFT in kilos.
    /// @param tokenId The id of the NFT to update.
    /// @return amount Total retired amount for an NFT in kilos.
    function getRetiredAmountInKilos(uint256 tokenId) external view returns (uint256) {
        uint256 amount = retirements[tokenId].amount;
        return amount / kiloDenomination;
    }
}
