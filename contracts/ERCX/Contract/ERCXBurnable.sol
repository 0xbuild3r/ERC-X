pragma solidity ^0.5.0;

import "./ERCXFull.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
contract ERCXBurnable is ERCXFull {
  /**
    * @dev Burns a specific ERCX item.
    * @param itemId uint256 id of the ERCXFull item to be burned.
    */
  function burn(uint256 itemId) public {
      _burn(itemId);
  }
}