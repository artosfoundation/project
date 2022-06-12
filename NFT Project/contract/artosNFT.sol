// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";



contract artosNFT is ERC721URIStorage{

    using Counters for Counters.Counter;
    Counters.Counter private nftTokenId;


    address contractAddress;

    constructor(address marketplaceAddress)ERC721("ArtosNFT","artosNFT"){

        contractAddress = marketplaceAddress;

    }

    function createNFtToken(string memory nftTokenURl)public  returns (uint256){
        nftTokenId.increment();
        uint256 id = nftTokenId.current();
        _mint(msg.sender,id);

        _setTokenURI(id,nftTokenURl);
   
        setApprovalForAll  (contractAddress,true);
    

        return id;
    
    }

        //ُTransfate nft after

  function transferToken(address from, address to, uint256 tokenId) external {
        require(ownerOf(tokenId) == from, "From address must be token owner");
        _transfer(from, to, tokenId);
    }


    function getContractAddress() public view returns (address){
      return contractAddress;
    }





}
