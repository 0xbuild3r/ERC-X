pragma solidity ^0.5.0;

import './IERCX.sol';

contract IERCXEnumerable is IERCX {
  function totalNumberOfItems() public view returns (uint256);
  function ownershipOfAddressByIndex(
    address owner,
    uint256 index
  )
    public
    view
    returns (uint256 itemId);

  function superOwnershipOfAddressByIndex(
    address superOwner,
    uint256 index
  )
    public
    view
    returns (uint256 itemId);

  function hyperOwnershipOfAddressByIndex(
    address hyperOwner,
    uint256 index
  )
    public
    view
    returns (uint256 itemId);


  function itemByIndex(uint256 index) public view returns (uint256);
}
