
// SPDX-License-Identifier: Unlicensed


pragma solidity ^0.8.9; //Same as in "Basel University - (2021) Smart Contracts and Decentralized Finance"


contract SimpleAuction {

    address public immutable beneficiary; // (SET AT DEPLOYMENT)
    uint public endTime; // As UNIX timestamp (SET AT DEPLOYMENT)
    /* endTime not declared immutable -> possibility of function for new Auctions? */

    // State of the Auction
    uint public highestBid;
    address public highestBidder;
    bool public hasEnded;

    // Amount wihtdrawable of previous bids
    mapping (address => uint) public pendingReturns;

    // Events:
    event NewBid (address indexed bidder, uint amount);
    event AuctionEnded (address winner, uint amount);

//_____________________________________________________________

    constructor (address _beneficiary, uint _durationMinutes) {

        beneficiary = _beneficiary;
        endTime = block.timestamp + _durationMinutes * 1 minutes;
        /* Could measure time via block.number (each block 12s (if there are not missed blocks)) */
    }
//_______________________________________________________________

    function bid() public payable {

        require(block.timestamp < endTime, 'Auction Ended'); //Could finish at specific block.number, instead
        require(msg.value > highestBid, 'Bid to small');
        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
            //storing qty to refund before updating to new highestBid
        }
        highestBid = msg.value;
        highestBidder = msg.sender;
        emit NewBid(msg.sender, msg.value);
    }

    function withdraw() external returns (uint amount) {

        amount = pendingReturns[msg.sender];

        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            payable(msg.sender).transfer(amount); /*  WOULD LIKE learning to use
            payable().call{value: <amount>, gas: <gas amount>.}("")  INSTEAD  */
        }

        //optional: return amount;
    }

    function auctionEnd() external {

        // 1. Check all conditions
        require(!hasEnded, 'Auction already ended'); // checking that hasEnded = FALSE (can't have ended yet)
        require(block.timestamp >= endTime, 'Wait for auction to end');

        // 2. Apply all internal state changes
        hasEnded = true;
        emit AuctionEnded(highestBidder, highestBid);

        // 3. Interact with other addresses
        payable(beneficiary).transfer(highestBid); /*  WOULD LIKE learning to use
        payable().call{value: <amount>, gas: <gas amount>.}("")  INSTEAD  */
    }

}