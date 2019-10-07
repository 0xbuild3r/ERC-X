pragma solidity ^0.5.0;

import '../introspection/IERC165.sol';

contract IERCX is IERC165 {

  event OwnershipTransferred(
    address indexed from,
    address indexed to,
    uint256 indexed itemId
  );

  event SuperOwnershipTransferred(
    address indexed from,
    address indexed to,
    uint256 indexed itemId
  );

  event HyperOwnershipTransferred(
    address indexed from,
    address indexed to,
    uint256 indexed itemId
  );

  event ApprovalOwnershipTransfer(
    address indexed owner,
    address indexed approved,
    uint256 indexed itemId
  );

  event ApprovalSuperOwnershipTransfer(
    address indexed owner,
    address indexed approved,
    uint256 indexed itemId
  );

  event ApprovalHyperOwnershipTransfer(
    address indexed owner,
    address indexed approved,
    uint256 indexed itemId
  );

  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  function balanceOfOwnerships(address user) public view returns (uint256 balance);
  function balanceOfSuperOwnerships(address user) public view returns (uint256 balance);
  function balanceOfHyperOwnerships(address user) public view returns (uint256 balance);
  function ownerOf(uint256 itemId) public view returns (address owner);
  function superOwnerOf(uint256 itemId) public view returns (address owner);
  function HyperOwnerOf(uint256 itemId) public view returns (address owner);

  function approveOwnershipTransfer(address to, uint256 itemId) public;
  function approveSuperOwnershipTransfer(address to, uint256 itemId) public;
  function approveHyperOwnershipTransfer(address to, uint256 itemId) public;

  function getApprovedForOwnershipTransfer(uint256 itemId)
    public view returns (address operator);
  function getApprovedForSuperOwnershipTransfer(uint256 itemId)
    public view returns (address operator);
  function getApprovedForHyperOwnershipTransfer(uint256 itemId)
    public view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) public;
  function isApprovedForAll(address owner, address operator)
    public view returns (bool);

  function transferOwnershipFrom(address from, address to, uint256 itemId) public;
  function safeTransferOwnershipFrom(address from, address to, uint256 itemId)
    public;
  function safeTransferOwnershipFrom(address from, address to, uint256 itemId, bytes memory data)
    public;
  function transferSuperOwnershipFrom(address from, address to, uint256 itemId) public;
  function safeTransferSuperOwnershipFrom(address from, address to, uint256 itemId)
    public;
  function safeTransferSuperOwnershipFrom(address from, address to, uint256 itemId, bytes memory data)
    public;
  function transferHyperOwnershipFrom(address from, address to, uint256 itemId) public;
  function safeTransferHyperOwnershipFrom(address from, address to, uint256 itemId)
    public;
  function safeTransferHyperOwnershipFrom(address from, address to, uint256 itemId, bytes memory data)
    public;

}