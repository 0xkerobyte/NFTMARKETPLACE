// SPDX-License-Identifier:  AGPL-3.0-only
pragma solidity ^0.8.19;

// Importar la interfaz de ERC721 para interactuar con los NFTs
import "../lib/forge-std/src/interfaces/IERC721.sol";

/// @title A marketplace for NFTs in Solidity
/// @author 0xkerobyte
/// @notice You can use this contract to create and accept buy and sell offers for NFTs
/// @dev This contract follows the natSpec standard and the check effects interactions pattern

contract NFTMarketplace {
    // Counter for sell orders
    uint256 public sellOfferCounter;

    // Counter for buy orders
    uint256 public buyOfferCounter;

    // Mapping to store sell orders
    mapping(uint256 => Offer) public sellOffers;

    // Mapping to store buy orders
    mapping(uint256 => Offer) public buyOffers;

    // Name of the marketplace
    string public marketplaceName;

    // Struct to represent an offer
    struct Offer {
        address nftAddress; // Address of the NFT contract
        uint256 tokenId; // ID of the NFT
        address offerer; // Address of the offer creator
        uint256 price; // Price in ETH for the offer
        uint256 deadline; // Maximum date by which the offer can be accepted
        bool isEnded; // Indicates if the offer has been accepted or canceled
    }

    /// @notice Constructor to set the marketplace name
    /// @param _marketplaceName The name of the marketplace
    constructor(string memory _marketplaceName) {
        marketplaceName = _marketplaceName;
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

    // This function is called by the NFT´s contract when an NFT before is going to be transferred to this contract
    // It must return the right value, otherwise will revert and the NFT will not be transferred
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        // Emits an event to register that the NFT is being received
        emit NFTReceived(operator, from, tokenId, data);

        // Returns the selector of the function to confirm the reception to proove the transfer was successful.
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
        // Validate sender is the owner of the NFT
        require(
            IERC721(_nftAddress).ownerOf(_tokenId) == msg.sender,
            "Only the owner can create a sell offer"
        );
        // Validate the contract has permissiont to transfer the NFT
        require(
            IERC721(_nftAddress).getApproved(_tokenId) == address(this),
            "Not allowed to transfer"
        );
        // Validate deadline is greater than current block timestamp
        require(_deadline > block.timestamp, "Invalid deadline");
        // Validate price is greater than 0
        require(_price > 0, "Price must be greater than 0");

        // Create the sell order
        uint256 offerId = sellOfferCounter;
        sellOffers[offerId] = Offer({
            nftAddress: _nftAddress,
            tokenId: _tokenId,
            offerer: msg.sender,
            price: _price,
            deadline: _deadline,
            isEnded: false
        });

        // Increment the sellOfferCounter
        sellOfferCounter++;

        // Transfer the NFT from the sender to the contract
        IERC721(_nftAddress).transferFrom(msg.sender, address(this), _tokenId);
        // Emit the SellOfferCreated event
        emit SellOfferCreated(offerId);
    }

    /// @notice Accepts a sell offer
    /// @param _offerId Identifier of the sell offer
    function acceptSellOffer(uint256 _offerId) external payable {
        Offer storage sellOffer = sellOffers[_offerId];
        // Validate sell offer has not been accepted
        require(!sellOffer.isEnded, "Sell offer already accepted");
        // Validate time limit has not passed
        require(block.timestamp <= sellOffer.deadline, "Sell offer expired");
        // Validate correct amount of ETH sent
        require(msg.value == sellOffer.price, "Incorrect ETH amount");

        // Mark the sell offer as ended
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
        require(!sellOffer.isEnded, "Sell order already ended");
        // Validate sender is the owner of the sell order
        require(msg.sender == sellOffer.offerer, "Not the offer creator");
        // Validate deadline has passed
        require(block.timestamp > sellOffer.deadline, "Deadline not passed");

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
        // Validate deadline is greater than current block timestamp
        require(_deadline > block.timestamp, "Invalid deadline");
        // Validate price (msg.value) is greater than 0
        require(msg.value > 0, "Price must be greater than 0");
        // We check the NFT exists in the contract
        bool proofNFT = checkIfTokenExist(_nftAddress, _tokenId);
        require(proofNFT, "NFT not for sale");

        // Create the buy order
        uint256 offerId = buyOfferCounter;
        buyOffers[offerId] = Offer({
            nftAddress: address(_nftAddress),
            tokenId: _tokenId,
            offerer: msg.sender,
            price: msg.value,
            deadline: _deadline,
            isEnded: false
        });

        // Increment the buyOfferCounter
        buyOfferCounter++;

        // Transfer the eth to nft owner which has accepted they buyer´s offer
        (bool sent, ) = address(this).call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        // Emit the BuyOfferCreated event
        emit BuyOfferCreated(offerId);
    }

    /// @notice Accepts a buy offer
    /// @param _offerId Identifier of the buy offer
    function acceptBuyOffer(uint256 _offerId) external {
        Offer storage buyOffer = buyOffers[_offerId];
        // Validate sender is the owner of the NFT
        require(
            IERC721(buyOffer.nftAddress).ownerOf(buyOffer.tokenId) ==
                msg.sender,
            "Not NFT owner"
        );
        // Validate the contract has permissiont to transfer the NFT
        require(
            IERC721(buyOffer.nftAddress).getApproved(buyOffer.tokenId) ==
                address(this),
            "Not allowed to transfer"
        );
        // Validate buy offer has not been accepted
        require(!buyOffer.isEnded, "Buy offer already accepted");
        // Validate time limit has not passed
        require(block.timestamp <= buyOffer.deadline, "Buy offer expired");

        // Mark the buy offer as ended
        buyOffer.isEnded = true;

        // Transfer the NFT to the buyer
        IERC721(buyOffer.nftAddress).safeTransferFrom(
            address(msg.sender),
            buyOffer.offerer,
            buyOffer.tokenId
        );

        // Transfer the eth to nft owner which has accepted they buyer´s offer
        (bool sent, ) = address(msg.sender).call{value: buyOffer.price}("");
        require(sent, "Failed to send Ether");

        // Emit the BuyOfferAccepted event
        emit BuyOfferAccepted(_offerId, msg.sender);
    }

    /// @notice Cancels a buy order
    /// @param _offerId Identifier of the buy order
    function cancelBuyOffer(uint256 _offerId) external {
        Offer storage buyOffer = buyOffers[_offerId];
        // Validate buy order has NOT ended
        require(!buyOffer.isEnded, "Buy order already ended");
        // Validate sender is the owner of the buy order
        require(msg.sender == buyOffer.offerer, "Not the offer creator");
        // Validate deadline has passed
        require(block.timestamp > buyOffer.deadline, "Deadline not passed");

        // Mark the buy order as ended
        buyOffer.isEnded = true;

        // Transfer ETH back to the creator
        (bool sent, ) = address(msg.sender).call{value: buyOffer.price}("");
        require(sent, "Failed to send Ether");

        // Emit the BuyOfferCancelled event
        emit BuyOfferCancelled(_offerId);
    }

    receive() external payable {}
}
