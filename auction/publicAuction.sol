// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SimpleAuction{

    address payable public beneficiary;
    uint public auctionEndTime;

    address public highestBidder;
    uint public hightestBid;

    mapping (address => uint) pendingReturns;

    // default false
    bool ended;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    error AuctionAlreadyEnded();
    error BidNotHighEnough(uint hightestBid);
    error AuctionNotEnded();
    error AuctionEndedAlreadyCalled();

    constructor(address payable beneficiaryAd, uint biddingTime){
        beneficiary = beneficiaryAd;
        auctionEndTime = block.timestamp + biddingTime;
    }

    function bid() external payable {
        if(block.timestamp > auctionEndTime){ // if(ended) ?
            revert AuctionAlreadyEnded();
        }

        if(msg.value <= hightestBid){
            revert BidNotHighEnough(hightestBid);
        }

        if(hightestBid > 0 ){
            pendingReturns[highestBidder] += hightestBid;
        }

        hightestBid = msg.value;
        highestBidder = msg.sender;
        emit HighestBidIncreased(highestBidder, hightestBid);
    }

    function withdraw() external returns(bool){
        uint amount = pendingReturns[msg.sender];
        if(amount > 0){
            pendingReturns[msg.sender] = 0;
        }
        if(!payable (msg.sender).send(amount)){
            pendingReturns[msg.sender] = amount;
            return false;
        }
        return true;
    }

    function auctionEnd() external {

        // 1. Check condition 
        if(block.timestamp < auctionEndTime){
            revert AuctionNotEnded();
        }
        // prevent transfer twice
        if(ended){
            revert AuctionEndedAlreadyCalled();
        }

        // 2. Perform action (may change condition) 
        ended = true;
        emit AuctionEnded(highestBidder, hightestBid);

        // 3. Interaction with other contracts 
        beneficiary.transfer(hightestBid);
    }
    
    // For a function that can interact with other contracts (meaning it calls other functions or sends ether), 
    // A good guideline is to structure it in three stages: 
    // 1. Check condition 
    // 2. Perform action (may change condition) 
    // 3. Interaction with other contracts 
    // If these phases are mixed, other contracts may call back the current contract and modify the state, 
    // or cause certain effects (such as paying ether) to take effect multiple times. 
    // If a function called within a contract contains an interaction with an external contract, 
    // it is also considered to have an interaction with an external contract.

}