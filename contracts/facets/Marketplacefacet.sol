// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Test, console2} from "forge-std/Test.sol";

import "solmate/tokens/ERC721.sol";
import {SignUtils} from "./libraries/SignUtils.sol";
import {Addlisting} from "../libraries/LibDiamond.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

contract Marketplacefacet{
    

    error InvalidAddress();

    constructor(){
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.admin = msg.sender;
    }
    function createListing(Addlisting calldata l)public returns(uint256 lid){
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ERC721(l.token).ownerOf(l.tokenId) == msg.sender,"You are not the owner of this token");
        require(ERC721(l.token).isApprovedForAll(msg.sender,address(this)),"not approve");
        require(l.price > 0,"Price must be greater than 0");
        require(l.deadline > block.timestamp,"Deadline must be greater than current time");
        
        //assert signature
        if (
            !SignUtils.isValid(
                SignUtils.constructMessageHash(
                    l.token,
                    l.tokenId,
                    l.price,
                    l.deadline,
                    l.lister
                ),
                l.sig,
                msg.sender
            )
        ) revert InvalidAddress();
        //append storage
        Addlisting storage li = ds.listings[ds.listingId];
        li.token = l.token;
        li.tokenId = l.tokenId;
        li.price = l.price;
        li.sig = l.sig;
        li.deadline = uint88(l.deadline);
        li.lister = msg.sender;
        li.active = true;
        console2.log("Listing created");
    }
        
    
    function executeListing(uint256 _listingId) public payable {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.listings[_listingId].active,"git");
        Addlisting storage l = ds.listings[_listingId];
        require(l.deadline > block.timestamp,"Listing is expired");
        require(l.price <= msg.value,"Not enough value");
         l.active = false;
          ERC721(l.token).transferFrom(
            l.lister,
            msg.sender,
            l.tokenId
        );

        // transfer eth
        payable(l.lister).transfer(l.price);

    }

    function editListing(
        uint256 _listingId,
        uint256 _newPrice,
        bool _active
    ) public{
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.listings[_listingId].active,"Listing is not active");
        Addlisting storage l = ds.listings[_listingId];
        require(l.lister == msg.sender,"You are not the lister of this listing");
        l.price = _newPrice;
        l.active = _active;
    }
    function fetchListing(
        uint256 _listingId
    ) public view returns (Addlisting memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        // if (_listingId >= listingId)
        return ds.listings[_listingId];
    }
}    
    


















