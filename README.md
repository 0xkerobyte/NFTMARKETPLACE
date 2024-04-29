# Marketplace NFT - Proxy UUPS

## The Project :

We're diving into a super exciting project: developing a Non-Fungible Token (NFT) marketplace using Solidity, a popular programming language for Ethereum blockchain apps. This marketplace is going to be a fantastic spot for users to buy, sell, and explore various NFTs in a safe and transparent way.

Here’s what you can look forward to:

Listing NFTs for Sale: You'll be able to list your own NFTs for sale, setting your prices and conditions just how you like.
Purchasing NFTs: Browse through a wide array of NFTs up for grabs and pick your favorites to purchase.

Placing Purchase Orders: If you’ve got your eye on something specific, you can place a purchase order with your preferred price.
Automatic Order Execution: When your purchase order matches a listed NFT at your specified price, the transaction happens automatically—seamlessly transferring ownership.

Secure Transactions: Every transaction is securely processed, ensuring that both funds and NFTs transfer correctly.
Transparent History: All transactions are recorded on the blockchain, so you can see the complete history of transactions for total clarity.

We’re also implementing a UUPS Proxy to make sure the marketplace can be updated and improved over time without any hassle for users or needing to redeploy the smart contract.

Testing with Foundry:
We’ve been putting everything through its paces using Foundry, a top-notch tool for testing Solidity smart contracts. It’s flexible, efficient, and makes sure our marketplace runs without a hitch.


## UUPS Proxy

The Proxy UUPS, or Universal Upgradeable Proxy Standard. It’s a special kind of smart contract in Solidity that makes upgrading the logic of a contract super smooth, without the need to redeploy the whole thing.

Think of a proxy like a middleman in Solidity. It sits between the user and another smart contract. When you make a function call, the proxy takes this and passes it along to the target smart contract. Once the target smart contract has processed it, the proxy sends the response right back to you.

Why is the UUPS Proxy so great?

Flexibility: It lets you update the contract's logic—like fixing bugs or adding new features—without the hassle of deploying a new contract.
Security: It boosts the security of smart contracts by allowing logic upgrades without altering the proxy's own code.
Efficiency: It's designed to streamline processes, allowing logic upgrades without needing to redeploy the entire contract code.
For those who dive deep, you can peek at the code itself in the OpenZeppelin library under openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol. This is where all the magic is detailed!

UUPS Proxies are a fantastic tool for keeping your blockchain applications flexible, secure, and efficient.



## The Components of the Project:

Solidity Version Directive :

pragma solidity ^0.8.23;
<br>
<br>
Library :

https://github.com/OpenZeppelin/openzeppelin-contracts
<br>
<br>
Inheritance :
<br>
<br>
UUPSUpgradeable

Storage - State Variables and Complex Types :

```solidity
    uint256 public sellOfferCounter;
    uint256 public buyOfferCounter;
    string public marketplaceName;
    address public contractOwner;

```
sellOfferIdCounter: This counter increases every time a new sales order is created, ensuring each one has a unique identifier.

buyOfferIdCounter: Similar to the sales counter, this one goes up with every new purchase order, also providing unique identifiers.

contractOwner: The owner of the smart contract.

marketplaceName: This is the name of our marketplace, which is set when the contract is initially created.

```solidity
    mapping(uint256 => Offer) public sellOffers;
    mapping(uint256 => Offer) public buyOffers;
```

'sellOffers': A mapping of uint256 to Offer, which records all the sell orders. In a sell order, the order creator lists an NFT for sale and sets the amount of ETH they wish to receive in exchange.

'buyOffers': A mapping of uint256 to Offer, which holds all the buy orders. In a buy order, the order creator specifies an amount of ETH they are offering and identifies the NFT they wish to acquire.

```solidity
    struct Offer {
        address nftAddress;
        uint256 tokenId; 
        address offerer;
        uint256 price; 
        uint256 deadline; 
        bool isEnded; 
    }
```

nftAddress: The address of the NFT contract being offered.
<br>
tokenId: The ID of the NFT that's up for offer.
<br>
offerer: The address of the person who created the offer.
<br>
price: The price of the offer, listed in Ethereum (ETH).
<br>
deadline: The last date by which the offer must be accepted.
<br>
isEnded: A true/false value indicating whether the offer has been accepted or cancelled.
<br>
<br>
EVENTS
<br>
<br>
```solidity
    event SellOfferCreated(uint256 indexed offerId);
    event SellOfferAccepted(uint256 indexed offerId, address indexed buyer);
    event SellOfferCancelled(uint256 indexed offerId);

    event BuyOfferCreated(uint256 indexed offerId);
    event BuyOfferAccepted(uint256 indexed offerId, address indexed seller);
    event BuyOfferCancelled(uint256 indexed offerId);
```
SellOfferCreated: Declares an event that logs the creation of a new sell offer with a unique identifier.

SellOfferAccepted: Declares an event that logs the acceptance of a sell offer, capturing the offer's unique identifier and the buyer's address.

SellOfferCancelled: Declares an event that logs the cancellation of a sell offer, noting its unique identifier.

BuyOfferCreated: Declares an event that logs the creation of a new buy offer with a unique identifier.

BuyOfferAccepted: Declares an event that logs the acceptance of a buy offer, capturing the offer's unique identifier and the seller's address.

BuyOfferCancelled: Declares an event that logs the cancellation of a buy offer, noting its unique identifier.
<br>
<br>
<br>
ERRORS
```solidity
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
```
<br>
NotOwner: Indicates that the caller is not the owner of the smart contract.
<br>
NotAllowedToTransfer: Indicates that the caller is not allowed to transfer the asset.
<br>
InvalidDeadline: Indicates that the provided deadline is invalid or has already passed.
<br>
PriceMustBeGreaterThanZero: Indicates that the price specified must be greater than zero.
<br>
SellOrderAlreadyEnded: Indicates that the sell order has already been ended.
<br>
NotOfferCreator: Indicates that the caller is not the creator of the offer.
<br>
DeadlineNotPassed: Indicates that the deadline for the offer has not yet passed.
<br>
SellOfferAlreadyAccepted: Indicates that the sell offer has already been accepted.
<br>
SellOfferExpired: Indicates that the sell offer has expired.
<br>
IncorrectETHAmount: Indicates that the amount of Ethereum sent is incorrect.
<br>
EtherTransferFailed: Indicates that the transfer of Ethereum failed.
<br>
NFTNotForSale: Indicates that the NFT is not currently for sale.
<br>
FailedToSendEther: Indicates that the attempt to send Ethereum failed.
<br>
NotNFTOwner: Indicates that the caller is not the owner of the NFT.
<br>
BuyOfferAlreadyAccepted: Indicates that the buy offer has already been accepted.
<br>
BuyOfferExpired: Indicates that the buy offer has expired.
<br>
BuyOrderAlreadyEnded: Indicates that the buy order has already been ended.
<br>

```solidity
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {...}
```
This function is called automatically by the NFT contract when an NFT is about to be transferred to this marketplace.
It ensures the successful reception of the NFT by emitting an event to acknowledge its arrival.
If the function does not return the correct value, the NFT transfer will fail.

```solidity
    function checkIfTokenExist(
        address NFTcontract,
        uint _tokenId
    ) public view returns (bool) {...}
```
Checks if a specific NFT exists within a collection by verifying its presence in the provided contract and with the given token ID.
This function is read-only and does not alter any state, providing a quick way to verify NFT existence without modifying the contract.

```solidity
function getSellOffer(uint256 _offerId) public view returns (address nftAddress, uint256 stokenId, address offerer, uint256 price, uint256 deadline, bool isEnded);
```
Retrieves the details of a selling offer by its unique identifier.
_offerId: The unique identifier of the selling offer.

nftAddress: The address of the NFT contract associated with the offer.
stokenId: The ID of the NFT being offered for sale.
offerer: The address of the seller who created the offer.
price: The price of the offer in ETH.
deadline: The maximum date by which the offer can be accepted.
isEnded: A boolean indicating whether the offer has ended.
```solidity
function getBuyOffer(uint256 _offerId) public view returns (address nftAddress, uint256 stokenId, address offerer, uint256 price, uint256 deadline, bool isEnded);
```
Retrieves the details of a buying offer by its unique identifier.
_offerId: The unique identifier of the buying offer.

nftAddress: The address of the NFT contract associated with the offer.
<br>
stokenId: The ID of the NFT being requested.
<br>
offerer: The address of the buyer who created the offer.
<br>
price: The price offered by the buyer in ETH.
<br>
deadline: The maximum date by which the offer can be accepted.
<br>
isEnded: A boolean indicating whether the offer has ended.
<br>
```solidity
function createSellOffer(address _nftAddress, uint256 _tokenId, uint256 _price, uint256 _deadline) external;
```
Creates a new sell offer for an NFT.
<br>
_nftAddress: The address of the NFT contract.
<br>
_tokenId: The ID of the NFT being offered for sale.
<br>
_price: The price of the NFT in ETH.
<br>
_deadline: The deadline by which the offer must be accepted.
<br>
```solidity
function acceptSellOffer(uint256 _offerId) external payable;
```
Accepts a sell offer.
_offerId: The unique identifier of the sell offer to accept.
```solidity
function cancelSellOffer(uint256 _offerId) external;
```
Cancels a sell offer.
_offerId: The unique identifier of the sell offer to cancel.
```solidity
function createBuyOffer(address _nftAddress, uint256 _tokenId, uint256 _deadline) external payable;
```
Creates a new buy offer for an NFT.
<br>
_nftAddress: The address of the NFT contract.
<br>
_tokenId: The ID of the NFT being requested.
<br>
_deadline: The deadline by which the offer must be accepted.
```solidity
function acceptBuyOffer(uint256 _offerId) external;
```
Accepts a buy offer.
_offerId: The unique identifier of the buy offer to accept.

function cancelBuyOffer(uint256 _offerId) external;

Cancels a buy offer.
_offerId: The unique identifier of the buy offer to cancel.

```solidity
function _authorizeUpgrade(address newImplementation) internal override;
```
Authorizes an upgrade to the smart contract's implementation.
newImplementation: The address of the new implementation contract.
```solidity
function version() public pure returns (uint256);
```
Retrieves the version of the implementation.
Returns: version of the implementation.

## Conclusion: Crafting Our NFT Marketplace

Building an NFT marketplace is quite the venture, calling for a solid grasp of Solidity along with a toolkit of relevant technologies.

1. Smart Contracts and Proxies

Smart Contracts: We use Solidity, a core programming language, to craft the rules that our marketplace operates by.
Proxies: To handle updates smoothly, we employ proxies. These clever tools keep our updating processes separate from the main logic of our contracts, making life easier.

2. Upgradability with Proxies

Adding a proxy layer does bring in some complexity, but it's a game-changer for keeping our marketplace up to date.
The proxy serves as a go-between for users and the actual contract functions, enabling us to tweak and improve our code without any hiccups for our users.

3. Testing with Foundry

We put Foundry to work to guarantee our marketplace's functionality and security. It's our go-to for:
Writing our tests directly in Solidity.
Running these tests using the forge test command.
Making sure everything performs flawlessly on the blockchain environment we choose.
In short, creating an NFT marketplace is a sophisticated yet thrilling task that blends development savvy with an in-depth knowledge of smart contracts and the strategic use of testing tools like Foundry.
