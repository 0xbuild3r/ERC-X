pragma solidity ^0.5.0;

import '../../Libraries/introspection/IERC165.sol';

contract IERCX is IERC165 {
  event Transfer(address indexed from, address indexed to, uint256 indexed itemId, uint256 layer, address operator);
  event Approval(address indexed owner, address indexed approved, uint256 itemId, uint256 layer);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
  event LienSet(address indexed attn, uint256 indexed itemId, bool status);
  event TenantRightSet(address indexed attn, uint256 indexed itemId, bool status);

  function balanceOf(address owner, uint256 layer) public view returns (uint256);
  function ownerOf(uint256 itemId, uint256 layer) public view returns (address);

  function safeTransfer(address from, address to, uint256 itemId, uint256 layer) public;
  function safeTransfer(address from, address to, uint256 itemId, uint256 layer, bytes memory data) public;

  function approveTransfer(address to, uint256 itemId, uint256 layer) public;
  function getApprovedTransfer(uint256 itemId, uint256 layer) public view returns(address);

  function setApprovalForAll(address operator, bool approved) public;
  function isApprovedForAll(address requester, address operator) public view returns (bool);

  function approveLien(address to, uint256 itemId) public;
  function getApprovedLien(uint256 itemId) public view returns(address);
  function setLien(uint256 itemId) public;
  function getCurrentLien(uint256 itemId) public view returns(address);
  function revokeLien(uint256 itemId) public;

  function approveTenantRight(address to, uint256 itemId) public;
  function getApprovedTenantRight(uint256 itemId) public view returns(address);
  function setTenantRight(uint256 itemId) public;
  function getCurrentTenantRight(uint256 itemId) public view returns(address);
  function revokeTenantRight(uint256 itemId) public;
}
