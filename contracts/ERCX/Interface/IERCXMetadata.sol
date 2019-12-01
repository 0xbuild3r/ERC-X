pragma solidity ^0.5.0;

import './IERCX.sol';
contract IERCXMetadata is IERCX {
  function itemURI(uint256 itemId) public view returns (string memory);
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
}