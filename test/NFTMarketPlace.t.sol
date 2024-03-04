// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";

import {MockERC721} from "../test/Mocks/ERC721mock.sol";

contract NFTMarketplaceTest is Test, MockERC721 {
    NFTMarketplace public nftmarketplace;
    MockERC721 public mockerc721;

    address nftOwner = address(1);
    address nonOwner = address(2);
    uint256 tokenId = 1;

    struct Offer {
        address nftAddress; // Address of the NFT contract
        uint256 tokenId; // ID of the NFT
        address offerer; // Address of the offer creator
        uint256 price; // Price in ETH for the offer
        uint256 deadline; // Maximum date by which the offer can be accepted
        bool isEnded; // Indicates if the offer has been accepted or canceled
    }

    event SellOfferCreated(uint256 indexed offerId);
    event SellOfferAccepted(uint256 indexed offerId, address indexed buyer);
    event SellOfferCancelled(uint256 indexed offerId);

    event BuyOfferCreated(uint256 indexed offerId);
    event BuyOfferAccepted(uint256 indexed offerId, address indexed seller);
    event BuyOfferCancelled(uint256 indexed offerId);

    function setUp() public {
        /// Marketplace Contract
        nftmarketplace = new NFTMarketplace("TESTING_PLACE");
        /// Mock ERC721 Contract
        mockerc721 = new MockERC721();
        /// We initialize the ERC721 Contract with the Name TEST
        mockerc721.initialize("TEST", "TST");

        vm.deal(nftOwner, 10 ether);
        assertEq(nftOwner.balance, 10 ether);

        vm.deal(nonOwner, 10 ether);
        assertEq(nonOwner.balance, 10 ether);

        // Mint NFT to nftOwner
        mockerc721.mint(address(nftOwner), tokenId);
    }

    function testOnERC721Received() public {
        /// Testing the OnERC721Received returns the right selector
        bytes4 selectorTest = nftmarketplace.onERC721Received(
            address(nftOwner),
            address(nftOwner),
            1,
            ""
        );

        bytes4 RightSelectorReturned = 0x150b7a02;

        // Checks the transfer was correct
        assertEq(selectorTest, RightSelectorReturned);
    }

    function testCreateSellOffer() public {
        /// Setting the enviroment
        vm.startPrank(address(nftOwner));

        /// Checks the owner of the NFT is nftOwner
        mockerc721.ownerOf(1);
        /// Approving the NFT
        mockerc721.approve(address(nftmarketplace), tokenId);

        /// Creates the sell Offer
        nftmarketplace.createSellOffer(
            address(mockerc721),
            tokenId,
            1 ether,
            block.timestamp + 1 days
        );

        /// Gets the data of the struct sellOffers with ID 0
        (
            address nftAddress,
            uint256 stokenId,
            address offerer,
            uint256 price,
            uint256 deadline,
            bool isEnded
        ) = nftmarketplace.sellOffers(0);

        /// Verifications

        assertEq(nftAddress, address(mockerc721));
        assertEq(stokenId, 1);
        assertEq(offerer, address(nftOwner));
        assertEq(price, 1 ether);
        assertEq(deadline, block.timestamp + 1 days);
        assertFalse(isEnded);

        vm.stopPrank();
    }

    function testFailCreateSellOfferNotOwner() public {
        // Attempt to create a sell offer as the Not NFT owner
        vm.startPrank(nonOwner);

        uint256 price = 1 ether;
        uint256 deadline = block.timestamp + 1 days;

        nftmarketplace.createSellOffer(
            address(mockerc721),
            tokenId,
            price,
            deadline
        );

        vm.expectRevert("Only the owner can create a sell offer");
        vm.stopPrank();
        assertEq(0, nftmarketplace.sellOfferCounter());
    }

    function testFailCreateSellOfferNotMinted() public {
        // Attempt to create a sell offer of an NFT not minted
        vm.startPrank(address(nftOwner));
        vm.expectRevert("NOT_MINTED");
        mockerc721.ownerOf(30);
        vm.expectRevert("NOT_MINTED");
    }

    function testFailCreateSellOfferWrongValue() public {
        // Attempt to create a sell offer as the NFT owner with wrong value of eth
        vm.startPrank(address(nftOwner));

        mockerc721.ownerOf(1);
        mockerc721.approve(address(nftmarketplace), tokenId);
        vm.expectRevert("Price must be greater than 0");
        nftmarketplace.createSellOffer(
            address(mockerc721),
            tokenId,
            0 ether,
            block.timestamp + 1 days
        );
        vm.expectRevert("Price must be greater than 0");
    }

    function testFailCreateSellOfferInvalidDeadline() public {
        // Attempt to create a sell offer as the NFT owner with invalid deadline
        vm.startPrank(address(nftOwner));

        mockerc721.ownerOf(1);
        mockerc721.approve(address(nftmarketplace), tokenId);
        nftmarketplace.createSellOffer(
            address(mockerc721),
            tokenId,
            1 ether,
            block.timestamp
        );
        vm.expectRevert("Invalid deadline");
        vm.stopPrank();
    }

    function testAcceptSellOffer() public {
        // Creates a sell offer as the NFT owner
        testCreateSellOffer();

        // Buys the NFT
        vm.startPrank(nonOwner);
        nftmarketplace.acceptSellOffer{value: 1 ether}(0);

        // Verifications
        assertEq(nftOwner.balance, 11 ether);
        assertEq(nonOwner.balance, 9 ether);
        assertTrue(mockerc721.ownerOf(tokenId) == nonOwner);
        vm.stopPrank();
    }

    function testFailAcceptSellOfferAlreadyAccepted() public {
        /// Attempt to create a sell offer as the NFT owner and accept it twice
        vm.startPrank(nftOwner);
        mockerc721.approve(address(nftmarketplace), tokenId);
        nftmarketplace.createSellOffer(
            address(mockerc721),
            tokenId,
            1 ether,
            block.timestamp + 1 days
        );
        vm.stopPrank();

        vm.startPrank(nonOwner);
        nftmarketplace.acceptSellOffer{value: 1 ether}(0); // We accept the offer
        nftmarketplace.acceptSellOffer{value: 1 ether}(0); // We try again, is already done though
        vm.expectRevert("Sell offer already accepted");
        vm.stopPrank();
    }

    function testFailAcceptSellOfferExpired() public {
        /// Attempt to create and accept an expired sell offer
        vm.startPrank(nftOwner);
        mockerc721.approve(address(nftmarketplace), tokenId);
        nftmarketplace.createSellOffer(
            address(mockerc721),
            tokenId,
            1 ether,
            block.timestamp + 2 days
        );
        vm.stopPrank();

        vm.startPrank(nonOwner);
        vm.warp(block.timestamp + 14 days);
        nftmarketplace.acceptSellOffer{value: 1 ether}(0);
        vm.expectRevert("Sell offer expired");
        vm.stopPrank();
    }

    function testFailAcceptSellOfferIncorrectETHAmount() public {
        /// Attempt to accept a sell offer sending wrong amount of eth
        vm.startPrank(nftOwner);
        mockerc721.approve(address(nftmarketplace), tokenId);
        nftmarketplace.createSellOffer(
            address(mockerc721),
            tokenId,
            1 ether,
            block.timestamp + 1 days
        );
        vm.stopPrank();
        /// NonOwner sends less amount of ether than the actual price
        vm.startPrank(nonOwner);
        nftmarketplace.acceptSellOffer{value: 0.5 ether}(0);
        vm.expectRevert("Incorrect ETH amount");
        vm.stopPrank();
    }

    function testCancelSellOffer() public {
        /// Creates a sell offer
        testCreateSellOffer();

        /// Going to the future, deadline will expire :)
        vm.warp(block.timestamp + 2 days);

        /// Cancel the offer as the owner
        vm.startPrank(nftOwner);
        nftmarketplace.cancelSellOffer(0);

        /// Verifications
        (, , , , , bool isEnded) = nftmarketplace.sellOffers(0);
        assertTrue(isEnded);
        vm.stopPrank();
    }

    function testFailCancelSellOfferNonExistent() public {
        /// Attempt to Cancel a fake offer
        uint nonExistentOfferId = 999; /// Fake ID
        vm.startPrank(nftOwner);
        nftmarketplace.cancelSellOffer(nonExistentOfferId);
        vm.expectRevert("Offer does not exist");
        vm.stopPrank();
    }

    function testFailCancelSellOfferNotOwner() public {
        /// Attempt to cancel an offer not being the owner
        vm.startPrank(nftOwner);
        mockerc721.approve(address(nftmarketplace), tokenId);

        /// Creates the offer
        nftmarketplace.createSellOffer(
            address(mockerc721),
            tokenId,
            1 ether,
            block.timestamp + 1 days
        );

        vm.stopPrank();

        // Trying to cancel the offer not being the owner
        vm.startPrank(nonOwner);
        nftmarketplace.cancelSellOffer(0);
        vm.expectRevert("Not the offer owner");
        vm.stopPrank();
    }

    function testFailCancelSellOfferAlreadyCanceled() public {
        /// Attempt to Cancel an offer already cancelled
        vm.startPrank(nftOwner);
        mockerc721.approve(address(nftmarketplace), tokenId);
        nftmarketplace.createSellOffer(
            address(mockerc721),
            tokenId,
            1 ether,
            block.timestamp + 1 days
        );

        vm.warp(block.timestamp + 14 days);

        // Cancelling the offer as the owner
        nftmarketplace.cancelSellOffer(0);
        vm.stopPrank();

        // Try again to cancel the same offer as the owner
        vm.startPrank(nftOwner);

        nftmarketplace.cancelSellOffer(0);
        vm.expectRevert("Sell order already ended");
        vm.stopPrank();
    }

    function testCreateBuyOffer() public {
        /// Setting the enviroment
        vm.startPrank(nonOwner);
        /// Keeping the balance of the contract to check it later
        uint256 balance = address(nftmarketplace).balance;
        /// Creates the buy offer ID 0
        nftmarketplace.createBuyOffer{value: 1 ether}(
            address(mockerc721),
            1,
            block.timestamp + 2 days
        );

        /// Getting the data of the offer just created
        (
            address nftAddress,
            uint256 stokenId,
            address offerer,
            uint256 price,
            uint256 deadline,
            bool isEnded
        ) = nftmarketplace.buyOffers(0);

        /// Verifications
        assertEq(nftAddress, address(mockerc721));
        assertEq(stokenId, 1);
        assertEq(offerer, address(nonOwner));
        assertEq(price, 1 ether);
        assertEq(balance + 1 ether, address(nftmarketplace).balance);
        assertEq(nonOwner.balance, 9 ether);
        assertEq(deadline, block.timestamp + 2 days);
        assertFalse(isEnded);

        vm.stopPrank();
    }

    function testFailCreateBuyOfferNFTNotForSale() public {
        /// Attemps to create a buy offer and the nft is not minted
        vm.startPrank(nonOwner);
        vm.expectRevert("NOT_MINTED");
        vm.expectRevert("NFT not for sale");
        nftmarketplace.createBuyOffer{value: 1 ether}(
            address(mockerc721),
            40,
            block.timestamp + 7 days
        );
        vm.stopPrank();
    }

    function testFailCreateBuyOfferWithoutValue() public {
        /// Setting the enviroment
        vm.startPrank(nonOwner);
        vm.deal(nonOwner, 2 ether);
        /// Attempts to create the buy offer
        nftmarketplace.createBuyOffer{value: 0 ether}(
            address(mockerc721),
            40,
            block.timestamp + 7 days
        );
        vm.expectRevert("Price must be greater than 0");
        vm.stopPrank();
    }

    function testFailCreateBuyOfferInvalidDeadline() public {
        /// Attempts to create an offer with Invalid Deadline
        vm.startPrank(nonOwner);
        vm.expectRevert("Invalid deadline");
        nftmarketplace.createBuyOffer{value: 1 ether}(
            address(mockerc721),
            1,
            block.timestamp
        );
        vm.expectRevert("Invalid deadline");
        vm.stopPrank();
    }

    function testCancelBuyOffer() public {
        /// Cancelling of a buy offer
        /// We set the enviroment and create the buy offer
        vm.startPrank(nonOwner);
        /// We save the nftmarketplace balance to check it later
        uint256 balance = address(nftmarketplace).balance;
        nftmarketplace.createBuyOffer{value: 1 ether}(
            address(mockerc721),
            1,
            block.timestamp + 2 days
        );
        /// Getting the info of the buy offer we have just created
        (
            address nftAddress,
            uint256 stokenId,
            address offerer,
            uint256 price,
            uint256 deadline,
            bool isEnded
        ) = nftmarketplace.buyOffers(0);

        assertEq(nftAddress, address(mockerc721));
        assertEq(stokenId, 1);
        assertEq(offerer, address(nonOwner));
        assertEq(price, 1 ether);
        assertEq(balance + 1 ether, address(nftmarketplace).balance);
        assertEq(nonOwner.balance, 9 ether);
        assertEq(deadline, block.timestamp + 2 days);
        assertFalse(isEnded);

        // Going to the future, deadline will expire :)
        vm.warp(block.timestamp + 14 days);

        // Cancel the buy offer
        nftmarketplace.cancelBuyOffer(0);

        // Verifications

        (, , address creator, , , bool isEnded2) = nftmarketplace.buyOffers(0);
        console.log(creator);
        assertTrue(isEnded2);
        vm.stopPrank();
    }

    function testFailCancelBuyOfferNonOwner() public {
        /// Attempts to cancel an offer not being the owner
        vm.startPrank(nonOwner);
        /// We save the nftmarketplace balance to check it later
        uint256 balance = address(nftmarketplace).balance;
        nftmarketplace.createBuyOffer{value: 1 ether}(
            address(mockerc721),
            1,
            block.timestamp + 2 days
        );

        /// Getting the info of the buy offer we have just created

        (
            address nftAddress,
            uint256 stokenId,
            address offerer,
            uint256 price,
            uint256 deadline,
            bool isEnded
        ) = nftmarketplace.buyOffers(0);

        assertEq(nftAddress, address(mockerc721));
        assertEq(stokenId, 1);
        assertEq(offerer, address(nonOwner));
        assertEq(price, 1 ether);
        assertEq(nonOwner.balance, 9 ether);
        assertEq(deadline, block.timestamp + 2 days);
        assertFalse(isEnded);

        // Going to the future, deadline will expire
        vm.warp(block.timestamp + 2 days);
        vm.stopPrank();
        vm.startPrank(nftOwner);

        // Cancel the buy offer
        vm.expectRevert("Not the offer creator");
        nftmarketplace.cancelBuyOffer(0);
        vm.expectRevert("Not the offer creator");

        // Verifications
        (, , , , , bool isEnded2) = nftmarketplace.buyOffers(0);
        assertEq(address(nftmarketplace).balance, balance);
        assertFalse(isEnded2);
        vm.stopPrank();
    }

    function testAcceptBuyOffer() public {
        // Accepting a buy offer, firstly we create a buy offer by nonOwner
        testCreateBuyOffer();
        /// Is accepted by the nftOwner
        vm.startPrank(nftOwner);
        mockerc721.ownerOf(1);
        mockerc721.approve(address(nftmarketplace), tokenId);

        nftmarketplace.acceptBuyOffer(0);
        (, , , , , bool isEnded) = nftmarketplace.buyOffers(0);

        vm.stopPrank();

        /// Checking the new owner is nonOwner and the offer has ended
        assertEq(mockerc721.ownerOf(1), nonOwner);
        assertTrue(isEnded);
    }

    function testFailAcceptBuyOfferAlreadyAccepted() public {
        /// Attempt to create a buy offer as the nonNFT owner and accept it twice by the nftOwner
        testCreateBuyOffer();
        vm.startPrank(nftOwner);
        mockerc721.ownerOf(1);
        mockerc721.approve(address(nftmarketplace), tokenId);
        nftmarketplace.acceptBuyOffer(0);
        (, , , , , bool isEnded) = nftmarketplace.buyOffers(0);

        nftmarketplace.acceptBuyOffer(0); // We accept the offer

        assertEq(mockerc721.ownerOf(1), nonOwner);
        assertTrue(isEnded);

        nftmarketplace.acceptBuyOffer(0); // We try again and it fails
        vm.expectRevert("Buy offer already accepted");
        vm.stopPrank();
    }

    function testFailAcceptBuyOfferInvalidDeadline() public {
        /// Attempts to create an offer with invalid deadline
        testCreateBuyOffer();

        /// Going to the future
        vm.warp(block.timestamp + 14 days);

        /// Setting the enviroment to accept the buy offer which has expired
        vm.startPrank(nftOwner);
        mockerc721.ownerOf(1);
        mockerc721.approve(address(nftmarketplace), tokenId);

        /// Trying to accept the buy offer which has expired
        nftmarketplace.acceptBuyOffer(0);

        /// Gets the data from the sturct to check later
        (, , , , , bool isEnded) = nftmarketplace.buyOffers(0);
        vm.expectRevert("Buy offer expired");
        nftmarketplace.acceptBuyOffer(0); // We try to accept the offer
        vm.expectRevert("Buy offer expired");

        /// Verifications

        /// Checks the Owner of the NFT is nftOwner
        assertEq(mockerc721.ownerOf(1), nftOwner);
        /// Checks the offer is ended
        assertTrue(isEnded);

        vm.stopPrank();
    }

    function testGetSellOffer() public {
        // Call getSellOffer with the offerId of the sell offer created in setUp
        (
            address nftAddress,
            uint256 stokenId,
            address offerer,
            uint256 price,
            uint256 deadline,
            bool isEnded
        ) = nftmarketplace.getSellOffer(0);

        /// Gets all the data from the struct

        (
            address nftAddress2,
            uint256 stokenId2,
            address offerer2,
            uint256 price2,
            uint256 deadline2,
            bool isEnded2
        ) = nftmarketplace.sellOffers(0);

        // Checks that the returned offer matches the expected values
        assertEq(nftAddress, nftAddress2);
        assertEq(stokenId, stokenId2);
        assertEq(offerer, offerer2);
        assertEq(price, price2);
        assertEq(deadline, deadline2);
        assertEq(isEnded, isEnded2);
    }

    function testGetBuyOffer() public {
        // Call getBuyOffer with the offerId of the sell offer created in setUp
        (
            address nftAddress,
            uint256 stokenId,
            address offerer,
            uint256 price,
            uint256 deadline,
            bool isEnded
        ) = nftmarketplace.getBuyOffer(0);

        /// Gets all the data from the struct

        (
            address nftAddress2,
            uint256 stokenId2,
            address offerer2,
            uint256 price2,
            uint256 deadline2,
            bool isEnded2
        ) = nftmarketplace.buyOffers(0);

        /// Checks that the returned offer matches the expected values
        assertEq(nftAddress, nftAddress2);
        assertEq(stokenId, stokenId2);
        assertEq(offerer, offerer2);
        assertEq(price, price2);
        assertEq(deadline, deadline2);
        assertEq(isEnded, isEnded2);
    }

    function testCheckIfTokenExistTrue() public {
        /// Checks if a token exists in a NFT contract
        assertTrue(nftmarketplace.checkIfTokenExist(address(mockerc721), 1));
    }

    function testFailCheckIfTokenExistFalse() public {
        /// Checks if a token exists in a NFT contract
        vm.expectRevert("NOT_MINTED");
        assertEq(
            nftmarketplace.checkIfTokenExist(address(mockerc721), 250),
            false
        );
    }
}
