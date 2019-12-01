pragma solidity ^0.5.0;

import '../../Libraries/introspection/IERC165.sol';

contract IERCX is IERC165 {

  event Transfer(address indexed operator, address indexed from, address indexed to, uint256 itemId, uint256 layer);
  event TransferLimitSet(address indexed operator, uint256 indexed itemId, uint256 indexed layer, bool satus);
  event ApprovalTransfer(address indexed owner, address indexed approved, uint256 itemId, uint256 layer);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
  event ApprovalTransferLimit(address indexed owner, address indexed approved, uint256 itemId, uint256 layer);

  function balanceOf(address owner, uint256 layer) public view returns (uint256);
  function ownerOf(uint256 itemId, uint256 layer) public view returns (address);
  function superOf(uint256 itemId, uint256 layer) public view returns (address);

  function safeTransferFrom(address from, address to, uint256 itemId, uint256 layer) public;
  function safeTransferFrom(address from, address to, uint256 itemId, uint256 layer, bytes memory data) public;

  function approveTransfer(address to, uint256 itemId, uint256 layer) public;
  function getApprovedTransfer(uint256 itemId, uint256 layer) public view returns(address);

  function setApprovalForAll(address operator, bool approved) public;
  function isApprovedForAll(address requester, address operator) public view returns (bool);

  function approveTransferLimitFor(address to, uint256 itemId, uint256 layer) public;
  function getApprovedTransferLimit(uint256 itemId, uint256 layer) public view returns(address);

  function setTransferLimitFor(uint256 itemId, uint256 layer) public;
  function revokeTransferLimitFor(uint256 itemId, uint256 layer) public;
}
