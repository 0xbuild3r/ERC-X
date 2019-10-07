
pragma solidity ^0.5.0;

import './ERCX.sol';
import './IERCXEnumerable.sol';

contract ERCXEnumerable is ERC165, ERCX, IERCXEnumerable {
  // Mapping from owner to list of owned item IDs
  mapping(address => uint256[]) private _ownedItems;
  mapping(address => uint256[]) private _superOwnedItems;
  mapping(address => uint256[]) private _hyperOwnedItems;

  // Mapping from item ID to index of the owner items list
  mapping(uint256 => uint256) private _ownedItemsIndex;
  mapping(uint256 => uint256) private _superOwnedItemsIndex;
  mapping(uint256 => uint256) private _hyperOwnedItemsIndex;

  // Array with all item ids, used for enumeration
  uint256[] private _allItems;

  // Mapping from item id to position in the allItems array
  mapping(uint256 => uint256) private _allItemsIndex;

  bytes4 private constant _InterfaceId_ERCXEnumerable = 
    bytes4(keccak256('totalNumberOfItems()')) ^
    bytes4(keccak256('ownershipOfAddressByIndex(address,uint256)')) ^
    bytes4(keccak256('superOwnershipOfAddressByIndex(address,uint256)')) ^
    bytes4(keccak256('hyperOwnershipOfAddressByIndex(address,uint256)')) ^
    bytes4(keccak256('itemByIndex(uint256)'));
  
  /**
   * @dev Constructor function
   */
  constructor() public {
    // register the supported interface to conform to ERCX via ERC165
    _registerInterface(_InterfaceId_ERCXEnumerable);
  }

  /**
   * @dev Gets the item ID at a given index of the items list of the requested owner
   * @param owner address owning the items list to be accessed
   * @param index uint256 representing the index to be accessed of the requested items list
   * @return uint256 item ID at the given index of the items list owned by the requested address
   */
   
  function ownershipOfAddressByIndex(
    address owner,
    uint256 index
  )
    public
    view
    returns (uint256)
  {
    require(index < balanceOfOwnerships(owner));
    return _ownedItems[owner][index];
  }

  function superOwnershipOfAddressByIndex(
    address superOwner,
    uint256 index
  )
    public
    view
    returns (uint256)
  {
    require(index < balanceOfSuperOwnerships(superOwner));
    return _superOwnedItems[superOwner][index];
  }

  function hyperOwnershipOfAddressByIndex(
    address hyperOwner,
    uint256 index
  )
    public
    view
    returns (uint256)
  {
    require(index < balanceOfHyperOwnerships(hyperOwner));
    return _hyperOwnedItems[hyperOwner][index];
  }

  /**
   * @dev Gets the total amount of items stored by the contract
   * @return uint256 representing the total amount of items
   */
  function totalNumberOfItems() public view returns (uint256) {
    return _allItems.length;
  }

  /**
   * @dev Gets the item ID at a given index of all the items in this contract
   * Reverts if the index is greater or equal to the total number of items
   * @param index uint256 representing the index to be accessed of the items list
   * @return uint256 item ID at the given index of the items list
   */
  function itemByIndex(uint256 index) public view returns (uint256) {
    require(index < totalNumberOfItems());
    return _allItems[index];
  }

  /**
   * @dev Internal function to add a item ID to the list of a given address
   * @param to address representing the new owner of the given item ID
   * @param itemId uint256 ID of the item to be added to the items list of the given address
   */
  function _addOwnershipTo(address to, uint256 itemId) internal {
    super._addOwnershipTo(to, itemId);
    uint256 length = _ownedItems[to].length;
    _ownedItems[to].push(itemId);
    _ownedItemsIndex[itemId] = length;
  }

  function _addSuperOwnershipTo(address to, uint256 itemId) internal {
    super._addSuperOwnershipTo(to, itemId);
    uint256 length = _superOwnedItems[to].length;
    _superOwnedItems[to].push(itemId);
    _superOwnedItemsIndex[itemId] = length;
  }

  function _addHyperOwnershipTo(address to, uint256 itemId) internal {
    super._addHyperOwnershipTo(to, itemId);
    uint256 length = _hyperOwnedItems[to].length;
    _hyperOwnedItems[to].push(itemId);
    _hyperOwnedItemsIndex[itemId] = length;
  }

  /**
   * @dev Internal function to remove a item ID from the list of a given address
   * @param from address representing the previous owner of the given item ID
   * @param itemId uint256 ID of the item to be removed from the items list of the given address
   */
  function _removeOwnershipFrom(address from, uint256 itemId) internal {
    super._removeOwnershipFrom(from, itemId);

    // To prevent a gap in the array, we store the last item in the index of the item to delete, and
    // then delete the last slot.
    uint256 itemIndex = _ownedItemsIndex[itemId];
    uint256 lastItemIndex = _ownedItems[from].length.sub(1);
    uint256 lastItem = _ownedItems[from][lastItemIndex];

    _ownedItems[from][itemIndex] = lastItem;
    // This also deletes the contents at the last position of the array
    _ownedItems[from].length--;

    // Note that this will handle single-element arrays. In that case, both itemIndex and lastItemIndex are going to
    // be zero. Then we can make sure that we will remove itemId from the ownedItems list since we are first swapping
    // the lastItem to the first position, and then dropping the element placed in the last position of the list

    _ownedItemsIndex[itemId] = 0;
    _ownedItemsIndex[lastItem] = itemIndex;
  }
  function _removeSuperOwnershipFrom(address from, uint256 itemId) internal {
    super._removeSuperOwnershipFrom(from, itemId);

    uint256 itemIndex = _superOwnedItemsIndex[itemId];
    uint256 lastItemIndex = _superOwnedItems[from].length.sub(1);
    uint256 lastItem = _superOwnedItems[from][lastItemIndex];

    _superOwnedItems[from][itemIndex] = lastItem;
    _superOwnedItems[from].length--;

    _superOwnedItemsIndex[itemId] = 0;
    _superOwnedItemsIndex[lastItem] = itemIndex;
  }

  function _removeHyperOwnershipFrom(address from, uint256 itemId) internal {
    super._removeHyperOwnershipFrom(from, itemId);

    uint256 itemIndex = _hyperOwnedItemsIndex[itemId];
    uint256 lastItemIndex = _hyperOwnedItems[from].length.sub(1);
    uint256 lastItem = _hyperOwnedItems[from][lastItemIndex];

    _hyperOwnedItems[from][itemIndex] = lastItem;
    _hyperOwnedItems[from].length--;

    _hyperOwnedItemsIndex[itemId] = 0;
    _hyperOwnedItemsIndex[lastItem] = itemIndex;
  }

  /**
   * @dev Internal function to mint a new item
   * Reverts if the given item ID already exists
   * @param to address the beneficiary that will own the minted item
   * @param itemId uint256 ID of the item to be minted by the msg.sender
   */
  function _mint(address to, uint256 itemId) internal {
    super._mint(to, itemId);

    _allItemsIndex[itemId] = _allItems.length;
    _allItems.push(itemId);
  }

  /**
   * @dev Internal function to burn a specific item
   * Reverts if the item does not exist
   * @param owner owner of the item to burn
   * @param itemId uint256 ID of the item being burned by the msg.sender
   */
  function _burn(address owner, uint256 itemId) internal {
    super._burn(owner, itemId);

    // Reorg all items array
    uint256 itemIndex = _allItemsIndex[itemId];
    uint256 lastItemIndex = _allItems.length.sub(1);
    uint256 lastItem = _allItems[lastItemIndex];

    _allItems[itemIndex] = lastItem;
    _allItems[lastItemIndex] = 0;

    _allItems.length--;
    _allItemsIndex[itemId] = 0;
    _allItemsIndex[lastItem] = itemIndex;
  }
}




