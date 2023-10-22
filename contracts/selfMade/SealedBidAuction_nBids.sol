
// SPDX-License-Identifier: Unlicensed


pragma solidity ^0.8.9; //Same as in "Basel University - (2021) Smart Contracts and Decentralized Finance"


contract SealedBidAuction {

    // Auction parameters (SET AT DEPLOYMENT)
    address public immutable beneficiary;
    uint public biddingEnd; // time when bidding finishes
    uint public revealEnd; // time when revealing finishes

    // State of the Auction
    uint public highestBid;
    address public highestBidder;
    bool public hasEnded;

    // Amount wihtdrawable of previous bids
    mapping (address => uint) public pendingReturns;

    // To associate a bid's hashes to a sent ETH amount, and to each participating address
    struct Bid {
        bytes32 sealedBid;
        uint deposit;
    }

    mapping (address => Bid[]) public bids;

    // Events:
    event AuctionEnded (address winner, uint amount);

    //
    modifier onlyBefore (uint time) {
        require(block.timestamp < time, "too late");
        _;

    }

    modifier onlyAfter (uint time) {
        require(block.timestamp > time, "too early");
        _;

    }

//_____________________________________________________________

    constructor (address _beneficiary, uint _durationBiddingMinutes, uint _durationRevealMinutes) {

        beneficiary = _beneficiary;
        biddingEnd = block.timestamp + _durationBiddingMinutes * 1 minutes;
        revealEnd = biddingEnd + _durationRevealMinutes * 1 minutes;
        /* Could measure time via block.number (each block 12s (if there are not missed blocks)) */
    }
//_______________________________________________________________

    function bid (bytes32 _sealedBid) external payable onlyBefore(biddingEnd) {

        Bid memory newBid = Bid(
            _sealedBid,
             msg.value
        
        );

        bids[msg.sender].push(newBid);
    }

    function updateHighestBid (address _bidder, uint _bidAmount) internal returns (bool success) {

        if (_bidAmount <= highestBid) {
            return false;
        }

        if (highestBidder != address(0)) {
            
            //Refund previous highest bidder:
            pendingReturns[highestBidder] += highestBid;
        }

        highestBid = _bidAmount;
        highestBidder = _bidder;
        return true;
    }

    
    function reveal (uint[] calldata _bidAmounts, bool[] calldata _areLegit, string[] calldata _secrets)
    external
    onlyAfter(biddingEnd)
    onlyBefore(revealEnd)
    {

        uint nBids = bids[msg.sender].length;
        require (_bidAmounts.length == nBids, "invalid number of bid amouns");
        require (_areLegit.length == nBids, "invalid number of bid legitimacy indicators");
        require (_secrets.length == nBids, "invalid number of bid secrets");

        uint totalRefund;

        for (uint i = 0; i < nBids; i++) {

            Bid storage bidToCheck = bids[msg.sender][i];

            (uint bidAmount, bool isLegit, string memory secret) = (_bidAmounts[i], _areLegit[i], _secrets[i]);
            bytes32 hashedInput = generateSealedBid(bidAmount, isLegit, secret);

            if(bidToCheck.sealedBid != hashedInput) {
            // Failed to reveal bid.
            // Do not refund deposit and continue with next bid.
            continue;
            }

            totalRefund += bidToCheck.deposit;

            if(isLegit && bidToCheck.deposit >= bidAmount) {

                bool success = updateHighestBid(msg.sender, bidAmount);
                if (success) {
                                  
                    totalRefund -= bidAmount;
                }
            }

            bidToCheck.sealedBid = bytes32(0); // delete msg.sender bids' hash to prevent re-claiming of the same deposit
        
        }
    
        if (totalRefund > 0) {

            payable(msg.sender).transfer(totalRefund);
        }
    
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

    function auctionEnd() external onlyAfter(revealEnd) {
        require(!hasEnded, "Auction already ended");

        emit AuctionEnded(highestBidder, highestBid);

        hasEnded = true;

        payable(beneficiary).transfer(highestBid);
    }

    function generateSealedBid(uint _bidAmount, bool _isLegit, string memory _secret) public pure returns (bytes32 sealedBid) {
            // A function to generate the HASH VALUE that will be used for the actual bidding

        sealedBid = keccak256(abi.encodePacked(_bidAmount, _isLegit, _secret));
    /*  · can explicitly make a FALSE bid (introducing _isLegit = FALSE)
        · a SECRET is introduced to PREVENT GUESSING from other participants:
          - in this case, a String:  stored in Memory (so, just being returned when using the function <= NOT IN contract STORAGE) */
    }

}