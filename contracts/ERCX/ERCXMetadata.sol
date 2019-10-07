pragma solidity ^0.5.0;

import './ERCX.sol';
import './IERCXMetadata.sol';

contract ERCXMetadata is ERC165, ERCX, IERCXMetadata {
  // item name
  string internal _name;

  // item symbol
  string internal _symbol;

  // Optional mapping for item URIs
  mapping(uint256 => string) private _itemURIs;

  bytes4 private constant InterfaceId_ERCXMetadata =
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('itemURI(uint256)'));

  /**
   * @dev Constructor function
   */
  constructor(string memory name, string memory symbol) public {
    _name = name;
    _symbol = symbol;

    // register the supported interfaces to conform to ERCX via ERC165
    _registerInterface(InterfaceId_ERCXMetadata);
  }

  /**
   * @dev Gets the item name
   * @return string representing the item name
   */
  function name() external view returns (string memory) {
    return _name;
  }

  /**
   * @dev Gets the item symbol
   * @return string representing the item symbol
   */
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns an URI for a given item ID
   * Throws if the item ID does not exist. May return an empty string.
   * @param itemId uint256 ID of the item to query
   */
  function itemURI(uint256 itemId) public view returns (string memory) {
    require(_isItemExists(itemId));
    return _itemURIs[itemId];
  }

  /**
   * @dev Internal function to set the item URI for a given item
   * Reverts if the item ID does not exist
   * @param itemId uint256 ID of the item to set its URI
   * @param uri string URI to assign
   */
  function _setItemURI(uint256 itemId, string memory uri) internal {
    require(_isItemExists(itemId));
    _itemURIs[itemId] = uri;
  }

  /**
   * @dev Internal function to burn a specific item
   * Reverts if the item does not exist
   * @param owner owner of the item to burn
   * @param itemId uint256 ID of the item being burned by the msg.sender
   */
  function _burn(address owner, uint256 itemId) internal {
    super._burn(owner, itemId);

    // Clear metadata (if any)
    if (bytes(_itemURIs[itemId]).length != 0) {
      delete _itemURIs[itemId];
    }
  }
}




