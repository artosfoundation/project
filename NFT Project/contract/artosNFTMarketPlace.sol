// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./artosNFT.sol";
import "./artosTokenNFT.sol";

contract artosNFTMarketPlace is ReentrancyGuard {

    address payable owner;
      using Counters for Counters.Counter;
     Counters.Counter private itemId;
    Counters.Counter private itemsSold;

     constructor(){
         owner = payable(msg.sender);
     }

    struct NftMerketItem{
              address nftContract;
        uint256 id;
        uint256 tokenId;
          //=>
        address payable creator;
        address  payable seller;
       address payable owner;

        uint256 price;
        bool sold;
        address oldOwner;
        address oldSeller;

        uint256 oldPrice;
        bool isResell;
      bool isBanned;
               bool soldFirstTime;


    }

        event NftMarketItemCreated(
        address  indexed nftContract,
        uint256 indexed id,
        uint256 tokenId,
       
        //=>
         address  creator,

        address  seller,
         address  owner,
        uint256 price,
        bool sold,
        address oldOwner,
         address oldSeller,

        uint256 oldPrice,
       bool isResell,
             bool isBanned,
                      bool soldFirstTime


        );
     //=>
     event ProductUpdated(
      uint256 indexed id,
      uint256 indexed newPrice,
       bool sold,
        address  owner,
         address  seller,
               bool isBanned,
                        bool soldFirstTime


    );
      //=>

      //=>
    event ProductSold(
        uint256 indexed id,
        address indexed nftContract,
        uint256 indexed tokenId,
        address creator,
        address seller,
        address owner,
        uint256 price,
        address oldOwner,
        address oldSeller,
        uint256 oldPrice,
        bool isResell,
         bool isBanned,
         bool soldFirstTime

    );
    //==>
           event ProductListed(
        uint256 indexed itemId
    );
       ///=>
        modifier onlyProductOrMarketPlaceOwner(uint256 id) {
        if (idForMarketItem[id].owner != address(0)) {
            require(idForMarketItem[id].owner == msg.sender);
        } else {
            require(
                idForMarketItem[id].seller == msg.sender || msg.sender == owner
            );
        }
        _;
    }

    modifier onlyProductSeller(uint256 id) {
        require(
            idForMarketItem[id].owner == address(0) &&
                idForMarketItem[id].seller == msg.sender, "Only the product can do this operation"
        );
        _;
    }

    modifier onlyItemOwner(uint256 id) {
        require(
            idForMarketItem[id].owner == msg.sender,
            "Only product owner can do this operation"
        );
        _;
    }

      modifier onlyItemOldOwner(uint256 id) {
        require(
            idForMarketItem[id].oldOwner == msg.sender,
            "Only product Old owner can do this operation"
        );
        _;
    }

    
///////////////////////////////////
     mapping(uint256=>NftMerketItem) private idForMarketItem;
///////////////////////////////////


    function createItemForSale(address nftContract,uint256 tokenId,uint256 price)public payable nonReentrant {
        require(price >0,"Price should be moreThan 1");
        require(tokenId >0,"token Id should be moreThan 1");
        require(nftContract != address(0),"address should not be equal 0x0");

         


        itemId.increment();
        uint256 id = itemId.current();

        idForMarketItem[id]= NftMerketItem(
              nftContract,
            id,
            tokenId,
            payable(msg.sender),
            payable(msg.sender),
            payable (address (0)),
            price,
            false,
            payable(address(0)),
            payable(address(0)),
            price,
            false,
            false,
            false
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
      
        emit NftMarketItemCreated(nftContract, id, tokenId,  msg.sender, msg.sender,address(0), price, false,address(0),address(0),price,false,false,false);

    }
    //Buy nft

    function buyNFt(address nftContract,uint256 nftItemId) public payable nonReentrant {
     uint256 price = idForMarketItem[nftItemId].price;
     uint256 tokenId = idForMarketItem[nftItemId].tokenId;

      IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId); //buy
      idForMarketItem[nftItemId].owner = payable(msg.sender);
      idForMarketItem[nftItemId].sold =  true;
    idForMarketItem[nftItemId].isResell =  true;
    idForMarketItem[nftItemId].soldFirstTime =  true;

      itemsSold.increment();


         
    }
     //REsell

     function putItemToResell(address nftContract, uint256 itemId, uint256 newPrice)
        public
        payable
        nonReentrant
        onlyItemOwner(itemId)
    {
        uint256 tokenId = idForMarketItem[itemId].tokenId;
        require(newPrice > 0, "Price must be at least 1 wei");

        artosNFT tokenContract = artosNFT(nftContract);

        tokenContract.transferToken(msg.sender, address(this), tokenId);

        address payable oldOwner = idForMarketItem[itemId].owner;
          address payable oldSeller = idForMarketItem[itemId].seller;

        uint256 oldPrice = idForMarketItem[itemId].price;

        idForMarketItem[itemId].owner = payable(address(0));
        idForMarketItem[itemId].seller = oldOwner;
        idForMarketItem[itemId].price = newPrice;
        idForMarketItem[itemId].sold = false;
        idForMarketItem[itemId].isResell = false;

        //Start to save old value
        idForMarketItem[itemId].oldOwner = oldOwner;
        idForMarketItem[itemId].oldSeller = oldSeller;
         idForMarketItem[itemId].oldPrice = oldPrice;
        
     itemsSold.decrement();
          emit ProductListed(itemId);

    }

//TO DO Send when cancel fees to Owner
        function cancelResellWitholdPrice(address nftContract,uint256 nftItemId) public  payable nonReentrant {
    uint256 price = idForMarketItem[nftItemId].oldPrice;
     uint256 tokenId = idForMarketItem[nftItemId].tokenId;



      IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId); //buy
      idForMarketItem[nftItemId].owner = payable(msg.sender);
      idForMarketItem[nftItemId].price = price;
       idForMarketItem[nftItemId].seller = payable(idForMarketItem[nftItemId].oldSeller);
      idForMarketItem[nftItemId].sold =  true;
      itemsSold.increment();

           emit ProductSold(
            idForMarketItem[nftItemId].id,
            idForMarketItem[nftItemId].nftContract,
            idForMarketItem[nftItemId].tokenId,
            idForMarketItem[nftItemId].creator,
            idForMarketItem[nftItemId].seller,
            payable(msg.sender),
            idForMarketItem[nftItemId].price,
            address(0),
            address(0),
            0,
            idForMarketItem[nftItemId].isResell,
            false,
            true
        );

    }

    //Bloack any NFT

     function blockNFtItem(uint256 nftItemId) public  payable nonReentrant  {
      idForMarketItem[nftItemId].isBanned =  true;

    }

    ///FETCH SINGLE NFT
  function fetchSingleItem(uint256 id) public view returns (NftMerketItem memory)
       
    {
        return idForMarketItem[id];
    }
    //=>Update Item =>We Dont Use This

    



function getMyItemCreated() public view returns(NftMerketItem[] memory){
uint256 totalItemCount = itemId.current(); 
uint myItemCount=0;//10
uint myCurrentIndex =0;

for(uint i = 0;i<totalItemCount;i++){
    if(idForMarketItem[i+1].creator == msg.sender){
        myItemCount+=1;

    }
}
NftMerketItem [] memory nftItems = new NftMerketItem[](myItemCount); //list[3]
for(uint i = 0;i<totalItemCount;i++){
    if(idForMarketItem[i+1].creator==msg.sender){      //[1,2,3,4,5]
      uint currentId = i+1;
        NftMerketItem storage  currentItem = idForMarketItem[currentId];
        nftItems[myCurrentIndex] = currentItem;
        myCurrentIndex +=1;
        
    }
}


return nftItems;

}


//Create My purchased Nft Item

function getMyNFTPurchased() public view returns(NftMerketItem[] memory){
uint256 totalItemCount = itemId.current(); 
uint myItemCount=0;//10
uint myCurrentIndex =0;

for(uint i = 0;i<totalItemCount;i++){
    if(idForMarketItem[i + 1 ].owner == msg.sender){
        myItemCount+=1;

    }
}

NftMerketItem [] memory nftItems = new NftMerketItem[](myItemCount); //list[3]
for(uint i = 0;i<totalItemCount;i++){
    if(idForMarketItem[i+1].owner== msg.sender){      //[1,2,3,4,5]
      uint currentId = i+1;
        NftMerketItem storage  currentItem = idForMarketItem[currentId];
        nftItems[myCurrentIndex] = currentItem;
        myCurrentIndex +=1;
        
    }
}


return nftItems;

}
//Fetch  all unsold nft items
function getAllUnsoldItems()public view returns (NftMerketItem[] memory){

uint256 totalItemCount = itemId.current(); 
uint myItemCount= itemId.current() - itemsSold.current();
uint myCurrentIndex =0;



NftMerketItem [] memory nftItems = new NftMerketItem[](myItemCount); //list[3]
for(uint i = 0;i<totalItemCount;i++){
    if(idForMarketItem[i+1].owner== address(0)){      //[1,2,3,4,5]
      uint currentId = i+1;
        NftMerketItem storage  currentItem = idForMarketItem[currentId];
        nftItems[myCurrentIndex] = currentItem;
        myCurrentIndex +=1;
        
    }
}


return nftItems;


}


//Get resell my items

function getMyResellItems() public view returns(NftMerketItem[] memory){
uint256 totalItemCount = itemId.current(); 
uint myItemCount=0;//10
uint myCurrentIndex =0;

for(uint i = 0;i<totalItemCount;i++){
    if((idForMarketItem[i + 1 ].seller == msg.sender)&&(idForMarketItem[i + 1 ].sold == false)){
        myItemCount+=1;

    }
}

NftMerketItem [] memory nftItems = new NftMerketItem[](myItemCount); //list[3]
for(uint i = 0;i<totalItemCount;i++){
    if((idForMarketItem[i + 1 ].seller == msg.sender)&&(idForMarketItem[i + 1 ].sold == false)){      //[1,2,3,4,5]
      uint currentId = i+1;
        NftMerketItem storage  currentItem = idForMarketItem[currentId];
        nftItems[myCurrentIndex] = currentItem;
        myCurrentIndex +=1;
        
    }
}


return nftItems;

}


function getAllBlockItems()public view returns (NftMerketItem[] memory){

uint256 totalItemCount = itemId.current(); 
uint myItemCount= itemId.current() - itemsSold.current();
uint myCurrentIndex =0;



NftMerketItem [] memory nftItems = new NftMerketItem[](myItemCount); //list[3]
for(uint i = 0;i<totalItemCount;i++){
    if((idForMarketItem[i + 1 ].isBanned == true)){
        //[1,2,3,4,5]
      uint currentId = i+1;
        NftMerketItem storage  currentItem = idForMarketItem[currentId];
        nftItems[myCurrentIndex] = currentItem;
        myCurrentIndex +=1;
        
    

    }
  
}


return nftItems;


}


function getAllUnBlockItems()public view returns (NftMerketItem[] memory){

uint256 totalItemCount = itemId.current(); 
uint myItemCount= itemId.current() - itemsSold.current();
uint myCurrentIndex =0;



NftMerketItem [] memory nftItems = new NftMerketItem[](myItemCount); //list[3]
for(uint i = 0;i<totalItemCount;i++){
    if((idForMarketItem[i + 1 ].isBanned == false)){
        //[1,2,3,4,5]
      uint currentId = i+1;
        NftMerketItem storage  currentItem = idForMarketItem[currentId];
        nftItems[myCurrentIndex] = currentItem;
        myCurrentIndex +=1;
        
    

    }
  
}


return nftItems;


}
}
