pragma solidity ^0.5.0;

import './IERCX.sol';

contract IERCXEnumerable is IERCX {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  )
    public
    view
    returns (uint256 tokenId);

  function tokenByIndex(uint256 index) public view returns (uint256);
}
