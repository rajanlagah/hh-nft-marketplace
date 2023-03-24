// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import "@openzappelin/contracts/token/ERC721/IERC721.sol";
import "@openzappelin/contracts/security/ReentrenceyGuard.sol";

error NFTMarketplace__PriceMustBeAboveZero();
error NFTMarketplace__NotApprovedForMarketplace();
error NFTMarketplace__ItemAlreadyListed( address nftAddress, uint256 tokenId);
error NFTMarketplace__InvalidOwner( address nftAddress, uint256 tokenId);
error NFTMarketplace__ItemNotListed( address nftAddress, uint256 tokenId);
error NFTMarketplace__PriceNotMet( address nftAddress, uint256 tokenId, uint256 nftPrice, uint256 sentMoney);
error NFTMarketplace__NoProceeds();
error NFTMarketplace__WithdrawProceedsFailed();

contract NFTMarketplace is ReentrenceyGuard {
    struct Listing {
        uint256 price;
        address sender;
    }

    event eventItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 indexed price
    )

    event eventItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 nftPrice
    )

    event eventItemCanceled(
        address indexed ownerAddress,
        address indexed nftAddress,
        uint256 indexed tokenId,
    )

    event eventItemUpdated(
        address indexed ownerAddress,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 newPrice
    )

    // NFT contract address -> NFT tokenId -> Listing
    mapping(address => mapping(uint256 => Listing)) private s_listings;

    // Seller address -> Earnings
    mapping(address => mapping(uint256 => uint256)) private s_proceeds;
    //////////////////////// 
    /// Modifiers     //////
    //////////////////////// 

    modifier itemIsListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftAddress][tokenId]
        if(listing.price < 0){
            revert NFTMarketplace__ItemNotListed(nftAddress, tokenId)
        }
        _;
    }

    modifier itemNotListed(address nftAddress, uint256 tokenId, address owner) {
        Listing memory listing = s_listings[nftAddress][tokenId]
        if(listing.price > 0){
            revert NFTMarketplace__ItemAlreadyListed(nftAddress, tokenId)
        }
        _;
    }

    modifier isItemOwner(address nftAddress, uint256 tokenId, address spender) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId)
        if(spender != owner){
            revert NFTMarketplace__InvalidOwner(nftAddress, tokenId)
        }
        _;
    }

    //////////////////////// 
    /// Main function  //////
    //////////////////////// 

    /**
         notice : function to list marketplace items
         @param nftAddress: Address of NFT
         @param tokenId: Token ID of NFT
         @param price: Price of NFT
    */
    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) 
    external 
    itemNotListed(nftAddress, tokenId, msg.sender)
    isItemOwner(nftAddress,tokenId, msg.sender)
    {
        if (price <= 0) {
            revert NFTMarketplace__PriceMustBeAboveZero();
        }
        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert NFTMarketplace__NotApprovedForMarketplace();
        }
        s_listings[nftAddress][tokenId] = Listing(price,msg.sender)
        emit eventItemListed(msg.sender, nftAddress, tokenId, price);
    }

    function buyItem(address nftAddress, uint256 tokenId) external payable nonReentrant itemIsListed(nftAddress, tokenId){
        Listing memory listedItem = s_listings[nftAddress][tokenId];
        if(msg.value < listedItem.price){
            revert NFTMarketplace__PriceNotMet(nftAddress,tokenId, listedItem.price, msg.value)
        }
        
        // update sellers balance
        s_proceeds[listedItem.seller] = s_proceeds[listedItem.seller] + msg.value;
        
        // remove nft from seller account
        delete (s_listings[nftAddress][tokenId])

        // transfer nft to buyer account
        IERC721(nftAddress).safeTransferFrom(listedItem.seller,msg.sender , tokenId);

        emit eventItemBought(msg.sender, nftAddress, tokenId,listedItem.price)
    
    }

    function cancelNftListing(nftAddress,tokenId) external itemIsListed(nftAddress,tokenId) isItemOwner(nftAddress,tokenId){
        delete (s_listings[nftAddress][tokenId])
        emit eventItemCanceled(msg.sender, nftAddress, tokenId)
    }

    function updateNFTPrice(nftAddress,tokenId,newPrice) external isItemListed(nftAddress,tokenId) isItemListed(nftAddress,tokenId){
        s_listings[nftAddress][tokenId].price = newPrice;
        emit eventItemUpdated(msg.sender,nftAddress,tokenId,newPrice)
    }
    function withdrawProceeds() external{
        uint256 userProceeds = s_proceeds[msg.sender];
        if( userProceeds <= 0){
            revert NFTMarketplace__NoProceeds();
        }
        s_proceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value=userProceeds}("");

        if(!success) {
            revert NFTMarketplace__WithdrawProceedsFailed();
        }
    }


    //////////////////////// 
    /// getter function  //////
    //////////////////////// 
}
