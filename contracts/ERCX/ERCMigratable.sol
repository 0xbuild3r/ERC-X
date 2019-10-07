pragma solidity ^0.5.0;

import './ERCXFull.sol';
import '../token/ERC721/ERC721Full.sol';

contract ERCXMigratable is ERCXFull {

  event migrated(uint256 indexed itemId);
  ERC721 internal _original;
  ERC721Full internal _originalFull;

  constructor(ERC721 original, ERC721Full originalFull) public {
    _original = original;
    _originalFull = originalFull;
  }

  function migrateWithURI(address to, uint256 itemId) public returns (bool){
    address ownership = _originalFull.ownerOf(itemId);
    require(msg.sender == ownership);
    string memory itemURI = _originalFull.tokenURI(itemId);
    _originalFull.approve(msg.sender, itemId);
    _originalFull.transferFrom(msg.sender, address(this), itemId);
    _mint(to, itemId);
    _setItemURI(itemId, itemURI);
    emit migrated(itemId);
    return true;
  }

  function migrate(address to, uint256 itemId) public returns (bool){
    address ownership = _original.ownerOf(itemId);
    require(msg.sender == ownership);
    _original.approve(msg.sender, itemId);
    _original.transferFrom(msg.sender, address(this), itemId);
    _mint(to, itemId);
    emit migrated(itemId);
    return true;
  }
}