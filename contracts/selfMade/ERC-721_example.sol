// SPDX-License-Identifier: MIT

// Warning: For educational purposes only. Do not use with real funds.

pragma solidity ^0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/64e48203cecad94f02de9891ecdeed4d629c6dae/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Hasoshi is ERC721Enumerable {
    using Strings for uint256;

    uint internal tokenCount;
    string internal baseURI;
    mapping (uint => uint) public tokenVariant; // stores for each tokenId which variant was minted

    constructor() ERC721("Hasoshi", "HAS") {
        baseURI = "https://raw.githubusercontent.com/joansajoansa/Smart-Contracts-DeFi/main/assets/hasoshi/json/";
    }

    function mint() public {
    // Determine which of the 10 variants is minted: 1% chance for variant 10, equal chance of 11% for variants 1-9
    // we will use block.timestamp as our Source of Randomness (not recommended for Production / Mainnet <= easily exploitable)

        uint d100 = block.timestamp % 100; //"random" number from 0-99
        uint variant = d100 % 10 + 1;
        if (variant == 10) {
            variant = d100 / 10 + 1;    // ONLY VARIANT 10 only if both the last and the second-last digits are 9
        }

        uint tokenId = ++tokenCount; // add +1 to tokenCount, then it equals tokenId
        tokenVariant[tokenId] = variant;
        _safeMint(msg.sender, tokenId);
/*      When implementing ERC721 from OpenZeppelin you always have to write your own mint function
        (_safeMint function (which is internal) will check on ERC721-received before minting) */        
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        uint variant = tokenVariant[tokenId];
        return string(
            abi.encodePacked(
                baseURI,
                variant.toString(), /* there is no "toString" for integers
                                    OpenZeppelin solves it importing a "Strings Library for uint256" from ../../utils */
                ".json"
            )

        );
    }

}