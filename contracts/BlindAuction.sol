// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract BlindAuction {

    struct Bid {
        bytes32 blindBid;
        uint deposit;
    }

    address payable public beneficiary;

    uint biddingEnd;
    uint revealEnd;
    bool auctionEnd;

    mapping (address => Bid[]) Bids;

    address public highestBidder;
    uint public highestBid;

    mapping (address => uint) pendingReturns;

    event AuctionEnded(address winner, uint amount);

    error TooEarly(uint time);
    error TooLate(uint time);
    error auctionEndAlreadyCalled();

    modifier onlyBefore(uint time){
        if(block.timestamp > time)  revert TooLate(time);
        _;
    }

    modifier onlyAfter(uint time){
        if(block.timestamp < time) revert TooEarly(time);
        _;
    }

    constructor(uint biddingTime, uint revealTime, address payable beneficiaryAd){
        biddingEnd = block.timestamp + biddingTime;
        revealEnd = biddingEnd + revealTime;
        beneficiary = beneficiaryAd;
    }

    function bid(bytes32 blindBid) external payable onlyBefore(biddingEnd){
        Bids[msg.sender].push(Bid({
            blindBid: blindBid,
            deposit: msg.value
        }));
    }

    function reveal(uint[] calldata values, bool[] calldata fakes, bytes32[] calldata secrets) 
    external onlyAfter(biddingEnd) onlyBefore(revealEnd){
        uint length = Bids[msg.sender].length;
        require(values.length == length);
        require(fakes.length == length);
        require(secrets.length == length);

        uint refund;
        for(uint i = 0; i < length; i++){
            Bid storage toCheckBid = Bids[msg.sender][i]; //? storage
            (uint value, bool fake, bytes32 secret) = (values[i], fakes[i], secrets[i]);
            if(toCheckBid.blindBid != keccak256(abi.encodePacked(value, fake, secret))){
                continue ;
            }
            refund += toCheckBid.deposit;
            if(!fake && toCheckBid.deposit >= value){ //? refund >= value
                if(placeBid(msg.sender, value))
                    refund -= value;
            }
            toCheckBid.blindBid = bytes32(0);
        }
        payable (msg.sender).transfer(refund);
    }

    function placeBid(address bidder, uint value)internal returns(bool){
        if(value <= highestBid) return false;
        if(highestBidder != address(0)){
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = bidder;
        highestBid = value;
        return true;
    }

    function withDraw() external {
        uint amount = pendingReturns[msg.sender];
        if(amount > 0){
            pendingReturns[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }
    }

    function auctionEnded() external onlyAfter(revealEnd){
        if(auctionEnd) revert auctionEndAlreadyCalled();
        emit AuctionEnded(highestBidder, highestBid);
        auctionEnd = true;
        beneficiary.transfer(highestBid);
    }

}