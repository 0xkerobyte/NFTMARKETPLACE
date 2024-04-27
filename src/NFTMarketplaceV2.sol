// SPDX-License-Identifier:  AGPL-3.0-only
pragma solidity ^0.8.23;

import "../../lib/forge-std/src/interfaces/IERC721.sol";
import {OwnableUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {Initializable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

/// @title A marketplace for NFTs in Solidity
/// @author 0xkerobyte
/// @notice You can use this contract to create and accept buy and sell offers for NFTs
/// @dev This contract follows the natSpec standard and the check effects interactions pattern

contract NFTMarketplaceV2 is UUPSUpgradeable {
    /// Counter for sell orders
    uint256 public sellOfferCounter;

    /// Counter for buy orders
    uint256 public buyOfferCounter;

    /// Mapping to store sell orders
    mapping(uint256 => Offer) public sellOffers;

    /// Mapping to store buy orders
    mapping(uint256 => Offer) public buyOffers;

    /// Name of the marketplace
    string public marketplaceName;

    /// Contract´s Owner
    address public contractOwner;

    /// Struct to represent an offer
    struct Offer {
        address nftAddress; /// Address of the NFT contract
        uint256 tokenId; /// ID of the NFT
        address offerer; /// Address of the offer creator
        uint256 price; /// Price in ETH for the offer
        uint256 deadline; /// Maximum date by which the offer can be accepted
        bool isEnded; /// Indicates if the offer has been accepted or canceled
    }

    /// @notice Constructor to set the marketplace name
    /// @param _marketplaceName The name of the marketplace
    constructor(string memory _marketplaceName) {
        marketplaceName = _marketplaceName;
        contractOwner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != contractOwner) revert NotOwner();
        _;
    }

    function initialize(string memory _marketplaceName) external initializer {
        marketplaceName = _marketplaceName;
        contractOwner = msg.sender;
    }

    event NFTReceived(
        address operator,
        address from,
        uint256 tokenId,
        bytes data
    );

    event SellOfferCreated(uint256 indexed offerId);
    event SellOfferAccepted(uint256 indexed offerId, address indexed buyer);
    event SellOfferCancelled(uint256 indexed offerId);

    event BuyOfferCreated(uint256 indexed offerId);
    event BuyOfferAccepted(uint256 indexed offerId, address indexed seller);
    event BuyOfferCancelled(uint256 indexed offerId);

    error NotOwner();
    error NotAllowedToTransfer();
    error InvalidDeadline();
    error PriceMustBeGreaterThanZero();
    error SellOrderAlreadyEnded();
    error NotOfferCreator();
    error DeadlineNotPassed();
    error SellOfferAlreadyAccepted();
    error SellOfferExpired();
    error IncorrectETHAmount();
    error EtherTransferFailed();
    error NFTNotForSale();
    error FailedToSendEther();
    error NotNFTOwner();
    error BuyOfferAlreadyAccepted();
    error BuyOfferExpired();
    error BuyOrderAlreadyEnded();

    /// This function is called by the NFT´s contract when an NFT before is going to be transferred to this contract
    /// It must return the right value, otherwise will revert and the NFT will not be transferred
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        /// Emits an event to register that the NFT is being received
        emit NFTReceived(operator, from, tokenId, data);

        /// Returns the selector of the function to confirm the reception to proove the transfer was successful.
        return this.onERC721Received.selector;
    }

    /// @notice Checks if an NFT exists in a collection
    /// @param NFTcontract Address of the NFT contract
    /// @param _tokenId ID of the NFT

    function checkIfTokenExist(
        address NFTcontract,
        uint _tokenId
    ) public view returns (bool) {
        try IERC721(address(NFTcontract)).ownerOf(_tokenId) returns (address) {
            return true;
        } catch {
            return false;
        }
    }

    /// @notice Gets the struct of anoffer by the ID.
    /// @param _offerId The ID of the selling offer

    function getSellOffer(
        uint256 _offerId
    )
        public
        view
        returns (
            address nftAddress,
            uint256 stokenId,
            address offerer,
            uint256 price,
            uint256 deadline,
            bool isEnded
        )
    {
        return (
            sellOffers[_offerId].nftAddress,
            sellOffers[_offerId].tokenId,
            sellOffers[_offerId].offerer,
            sellOffers[_offerId].price,
            sellOffers[_offerId].deadline,
            sellOffers[_offerId].isEnded
        );
    }

    /// @notice Gets the struct of anoffer by the ID.
    /// @param _offerId The ID of the selling offer

    function getBuyOffer(
        uint256 _offerId
    )
        public
        view
        returns (
            address nftAddress,
            uint256 stokenId,
            address offerer,
            uint256 price,
            uint256 deadline,
            bool isEnded
        )
    {
        return (
            buyOffers[_offerId].nftAddress,
            buyOffers[_offerId].tokenId,
            buyOffers[_offerId].offerer,
            buyOffers[_offerId].price,
            buyOffers[_offerId].deadline,
            buyOffers[_offerId].isEnded
        );
    }

    /// @notice Creates a sell order for an NFT
    /// @param _nftAddress Address of the NFT contract
    /// @param _tokenId ID of the NFT
    /// @param _price Price in ETH for the offer
    /// @param _deadline Maximum date by which the offer can be accepted
    function createSellOffer(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _deadline
    ) external {
        /// Validate sender is the owner of the NFT
        if (IERC721(_nftAddress).ownerOf(_tokenId) != msg.sender)
            revert NotNFTOwner();

        /// Validate the contract has permission to transfer the NFT
        if (IERC721(_nftAddress).getApproved(_tokenId) != address(this))
            revert NotAllowedToTransfer();

        /// Validate deadline is greater than current block timestamp
        if (_deadline <= block.timestamp) revert InvalidDeadline();

        /// Validate price is greater than 0
        if (_price <= 0) revert PriceMustBeGreaterThanZero();

        /// Create the sell order and increment the sellOfferCounter
        uint256 offerId = sellOfferCounter++;
        sellOffers[offerId] = Offer({
            nftAddress: _nftAddress,
            tokenId: _tokenId,
            offerer: msg.sender,
            price: _price,
            deadline: _deadline,
            isEnded: false
        });

        /// Transfer the NFT from the sender to the contract
        IERC721(_nftAddress).transferFrom(msg.sender, address(this), _tokenId);
        /// Emit the SellOfferCreated event
        emit SellOfferCreated(offerId);
    }

    /// @notice Accepts a sell offer
    /// @param _offerId Identifier of the sell offer
    function acceptSellOffer(uint256 _offerId) external payable {
        Offer storage sellOffer = sellOffers[_offerId];

        /// Validate sell offer has not been accepted
        if (sellOffer.isEnded) revert SellOfferAlreadyAccepted();

        /// Validate time limit has not passed
        if (block.timestamp > sellOffer.deadline) revert SellOfferExpired();

        /// Validate correct amount of ETH sent
        if (msg.value != sellOffer.price) revert IncorrectETHAmount();

        /// Mark the sell offer as ended
        sellOffer.isEnded = true;

        // Tranfer the NFT to the new owner
        IERC721(sellOffer.nftAddress).safeTransferFrom(
            address(this),
            address(msg.sender),
            sellOffer.tokenId
        );

        // Transfer the eth to the sell offer creator
        (bool sent, ) = sellOffer.offerer.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        // Emit the SellOfferAccepted event
        emit SellOfferAccepted(_offerId, msg.sender);
    }

    /// @notice Cancels a sell order
    /// @param _offerId Identifier of the sell order
    function cancelSellOffer(uint256 _offerId) external {
        Offer storage sellOffer = sellOffers[_offerId];
        // Validate sell order has NOT ended
        if (sellOffer.isEnded) revert SellOrderAlreadyEnded();

        // Validate sender is the owner of the sell order
        if (msg.sender != sellOffer.offerer) revert NotOfferCreator();

        // Validate deadline has passed
        if (block.timestamp <= sellOffer.deadline) revert DeadlineNotPassed();

        // Mark the sell order as ended
        sellOffer.isEnded = true;

        // Transfer the NFT back to the creator
        IERC721(sellOffer.nftAddress).safeTransferFrom(
            address(this),
            sellOffer.offerer,
            sellOffer.tokenId
        );

        // Emit the SellOfferCancelled event
        emit SellOfferCancelled(_offerId);
    }

    /// @notice Creates a buy order for an NFT
    /// @param _nftAddress the NFT contract address
    /// @param _tokenId ID of the NFT
    /// @param _deadline Maximum date by which the offer can be accepted
    function createBuyOffer(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _deadline
    ) external payable {
        /// Validate deadline is greater than current block timestamp
        if (_deadline <= block.timestamp) revert InvalidDeadline();

        /// Validate price (msg.value) is greater than 0
        if (msg.value == 0) revert PriceMustBeGreaterThanZero();

        /// We check the NFT exists in the contract
        bool proofNFT = checkIfTokenExist(_nftAddress, _tokenId);
        if (!proofNFT) revert NFTNotForSale();

        /// Create the buy order and increment the buy offer
        uint256 offerId = buyOfferCounter++;
        buyOffers[offerId] = Offer({
            nftAddress: address(_nftAddress),
            tokenId: _tokenId,
            offerer: msg.sender,
            price: msg.value,
            deadline: _deadline,
            isEnded: false
        });

        /// Transfer the eth to nft owner which has accepted they buyer´s offer
        (bool sent, ) = address(this).call{value: msg.value}("");
        if (!sent) revert FailedToSendEther();

        /// Emit the BuyOfferCreated event
        emit BuyOfferCreated(offerId);
    }

    /// @notice Accepts a buy offer
    /// @param _offerId Identifier of the buy offer
    function acceptBuyOffer(uint256 _offerId) external {
        Offer storage buyOffer = buyOffers[_offerId];

        /// Validate sender is the owner of the NFT
        if (
            IERC721(buyOffer.nftAddress).ownerOf(buyOffer.tokenId) != msg.sender
        ) revert NotNFTOwner();

        /// Validate the contract has permissiont to transfer the NFT
        if (
            IERC721(buyOffer.nftAddress).getApproved(buyOffer.tokenId) !=
            address(this)
        ) revert NotAllowedToTransfer();

        /// Validate buy offer has not been accepted
        if (buyOffer.isEnded) revert BuyOfferAlreadyAccepted();

        /// Validate time deadline has not passed
        if (block.timestamp > buyOffer.deadline) revert BuyOfferExpired();

        /// Mark the buy offer as ended
        buyOffer.isEnded = true;

        /// Transfer the NFT to the buyer
        IERC721(buyOffer.nftAddress).safeTransferFrom(
            address(msg.sender),
            buyOffer.offerer,
            buyOffer.tokenId
        );

        /// Transfer the eth to nft owner which has accepted they buyer´s offer
        (bool sent, ) = address(msg.sender).call{value: buyOffer.price}("");
        if (!sent) revert FailedToSendEther();

        /// Emit the BuyOfferAccepted event
        emit BuyOfferAccepted(_offerId, msg.sender);
    }

    /// @notice Cancels a buy order
    /// @param _offerId Identifier of the buy order
    function cancelBuyOffer(uint256 _offerId) external {
        Offer storage buyOffer = buyOffers[_offerId];
        /// Validate buy order has NOT ended
        if (buyOffer.isEnded) revert BuyOrderAlreadyEnded();

        /// Validate sender is the owner of the buy order
        if (msg.sender != buyOffer.offerer) revert NotOfferCreator();

        /// Validate deadline has passed
        if (block.timestamp <= buyOffer.deadline) revert DeadlineNotPassed();

        /// Mark the buy order as ended
        buyOffer.isEnded = true;

        /// Transfer ETH back to the creator
        (bool sent, ) = address(msg.sender).call{value: buyOffer.price}("");
        if (!sent) revert FailedToSendEther();

        /// Emit the BuyOfferCancelled event
        emit BuyOfferCancelled(_offerId);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function version() public pure returns (uint256) {
        return 2;
    }

    receive() external payable {}
}
