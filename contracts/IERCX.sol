pragma solidity ^0.5.0;

import './IERC165.sol';

contract IERCX is IERC165 {

  event OwnershipTransferred(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  event SuperOwnershipTransferred(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  event HyperOwnershipTransferred(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  event SuperOwnershipTransferredByEnforcement(
    address indexed executor,
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  event ownershipTransferredByEnforcement(
    address indexed executor,
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  event ApprovalOwnershipTransfer(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );

  event ApprovalSuperOwnershipTransfer(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );

  event ApprovalHyperOwnershipTransfer(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );

  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  function balanceOf(address owner) public view returns (uint256[2] memory balance);
  function ownerOf(uint256 tokenId) public view returns (address owner);
  function superOwnerOf(uint256 tokenId) public view returns (address owner);
  function HyperOwnerOf(uint256 tokenId) public view returns (address owner);

  function approveOwnershipTransfer(address to, uint256 tokenId) public;
  function approveSuperOwnershipTransfer(address to, uint256 tokenId) public;
  function approveHyperOwnershipTransfer(address to, uint256 tokenId) public;

  function getApprovedForOwnershipTransfer(uint256 tokenId)
    public view returns (address operator);
  function getApprovedForSuperOwnershipTransfer(uint256 tokenId)
    public view returns (address operator);
  function getApprovedForHyperOwnershipTransfer(uint256 tokenId)
    public view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) public;
  function isApprovedForAll(address owner, address operator)
    public view returns (bool);

  function transferOwnershipFrom(address from, address to, uint256 tokenId) public;
  function safeTransferOwnershipFrom(address from, address to, uint256 tokenId)
    public;
  function safeTransferOwnershipFrom(address from, address to, uint256 tokenId, bytes memory data)
    public;
  function transferSuperOwnershipFrom(address from, address to, uint256 tokenId) public;
  function safeTransferSuperOwnershipFrom(address from, address to, uint256 tokenId)
    public;
  function safeTransferSuperOwnershipFrom(address from, address to, uint256 tokenId, bytes memory data)
    public;
  function transferHyperOwnershipFrom(address from, address to, uint256 tokenId) public;
  function safeTransferHyperOwnershipFrom(address from, address to, uint256 tokenId)
    public;
  function safeTransferHyperOwnershipFrom(address from, address to, uint256 tokenId, bytes memory data)
    public;

}