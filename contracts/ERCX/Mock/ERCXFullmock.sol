pragma solidity ^0.5.0;

import "../Contract/ERCXMintable.sol";
import "../Contract/ERCXBurnable.sol";

/**
 * @title ERCXFullmock
 * This mock just provides a public safeMint, mint, and burn functions for testing purposes
 */
contract ERCXFullmock is ERCXMintable, ERCXBurnable {

  constructor(string memory name, string memory symbol) ERCXMintable(name, symbol)
    public
  {
  }

  function exists(uint256 itemId) public view returns (bool) {
      return _exists(itemId,1);
  }

  function setItemURI(uint256 itemId, string memory uri) public {
      _setItemURI(itemId, uri);
  }

  function setBaseURI(string memory uri) public {
      _setBaseURI(uri);
  }

}