// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import "@openzappelin/contracts/token/ERC721/IERC721.sol";

error NFTMarketplace__PriceMustBeAboveZero();
error NFTMarketplace__NotApprovedForMarketplace();
error NFTMarketplace__ItemAlreadyListed( address nftAddress, uint256 tokenId);
error NFTMarketplace__InvalidOwner( address nftAddress, uint256 tokenId);

contract NFTMarketplace {
    struct Listing {
        uint256 price;
        address sender;
    }
    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 indexed price
    )
    // NFT contract address -> NFT tokenId -> Listing
    mapping(address => mapping(uint256 => Listing)) private s_listings;

    //////////////////////// 
    /// Modifiers     //////
    //////////////////////// 

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
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }
}
