pragma solidity ^0.5.0;

import './IERCX.sol';
contract IERCXMetadata is IERCX {
  function name() external view returns (string);
  function symbol() external view returns (string);
  function tokenURI(uint256 tokenId) public view returns (string);
}