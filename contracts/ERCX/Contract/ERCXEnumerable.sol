pragma solidity ^0.5.0;

import "./ERCX.sol";
import "../Interface/IERCXEnumerable.sol";

contract ERCXEnumerable is ERC165, ERCX, IERCXEnumerable {
    // Mapping from layer to owner to list of owned item IDs
    mapping(uint256 => mapping(address => uint256[])) private _ownedItems;

    // Mapping from layer to item ID to index of the owner items list
    mapping(uint256 => mapping(uint256 => uint256)) private _ownedItemsIndex;

    // Array with all item ids, used for enumeration
    uint256[] private _allItems;

    // Mapping from item id to position in the allItems array
    mapping(uint256 => uint256) private _allItemsIndex;

    bytes4 private constant _InterfaceId_ERCXEnumerable = bytes4(
        keccak256("totalNumberOfItems()")
    ) ^
        bytes4(keccak256("itemOfOwnerByIndex(address,uint256,uint256)")) ^
        bytes4(keccak256("itemByIndex(uint256)"));

    /**
   * @dev Constructor function
   */
    constructor() public {
        // register the supported interface to conform to ERCX via ERC165
        _registerInterface(_InterfaceId_ERCXEnumerable);
    }

    /**
   * @dev Gets the item ID at a given index of the items list of the requested user
   * @param user address owning the items list to be accessed
   * @param index uint256 representing the index to be accessed of the requested items list
   * @return uint256 item ID at the given index of the items list owned by the requested address
   */

    function itemOfUserByIndex(address user, uint256 index)
        public
        view
        returns (uint256)
    {
        require(index < balanceOfUser(user));
        return _ownedItems[1][user][index];
    }

    /**
   * @dev Gets the item ID at a given index of the items list of the requested owner
   * @param owner address owning the items list to be accessed
   * @param index uint256 representing the index to be accessed of the requested items list
   * @return uint256 item ID at the given index of the items list owned by the requested address
   */

    function itemOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256)
    {
        require(index < balanceOfOwner(owner));
        return _ownedItems[2][owner][index];
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
    * @dev Internal function to transfer ownership of a given item ID to another address.
    * As opposed to transfer, this imposes no restrictions on msg.sender.
    * @param from current owner of the item
    * @param to address to receive the ownership of the given item ID
    * @param itemId uint256 ID of the item to be transferred
    * @param layer uint256 number to specify the layer
    */
    function _transfer(address from, address to, uint256 itemId, uint256 layer)
        internal
    {
        super._transfer(from, to, itemId, layer);
        _removeItemFromOwnerEnumeration(from, itemId, layer);
        _addItemToOwnerEnumeration(to, itemId, layer);
    }

    /**
    * @dev Internal function to mint a new item.
    * Reverts if the given item ID already exists.
    * @param to address the beneficiary that will own the minted item
    * @param itemId uint256 ID of the item to be minted
    */
    function _mint(address to, uint256 itemId) internal {
        super._mint(to, itemId);

        _addItemToOwnerEnumeration(to, itemId, 1);
        _addItemToOwnerEnumeration(to, itemId, 2);

        _addItemToAllItemsEnumeration(itemId);
    }

    /**
    * @dev Internal function to burn a specific item.
    * Reverts if the item does not exist.
    * Deprecated, use {ERCX-_burn} instead.
    * @param itemId uint256 ID of the item being burned
    */
    function _burn(uint256 itemId) internal {
        address user = userOf(itemId);
        address owner = ownerOf(itemId);

        super._burn(itemId);

        _removeItemFromOwnerEnumeration(user, itemId, 1);
        _removeItemFromOwnerEnumeration(owner, itemId, 2);

        // Since itemId will be deleted, we can clear its slot in _ownedItemsIndex to trigger a gas refund
        _ownedItemsIndex[1][itemId] = 0;
        _ownedItemsIndex[2][itemId] = 0;

        _removeItemFromAllItemsEnumeration(itemId);

    }

    /**
    * @dev Private function to add a item to this extension's ownership-tracking data structures.
    * @param to address representing the new owner of the given item ID
    * @param itemId uint256 ID of the item to be added to the items list of the given address
    */
    function _addItemToOwnerEnumeration(
        address to,
        uint256 itemId,
        uint256 layer
    ) private {
        _ownedItemsIndex[layer][itemId] = _ownedItems[layer][to].length;
        _ownedItems[layer][to].push(itemId);
    }

    /**
    * @dev Private function to add a item to this extension's item tracking data structures.
    * @param itemId uint256 ID of the item to be added to the items list
    */
    function _addItemToAllItemsEnumeration(uint256 itemId) private {
        _allItemsIndex[itemId] = _allItems.length;
        _allItems.push(itemId);
    }

    /**
    * @dev Private function to remove a item from this extension's ownership-tracking data structures. Note that
    * while the item is not assigned a new owner, the `_ownedItemsIndex` mapping is _not_ updated: this allows for
    * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
    * This has O(1) time complexity, but alters the order of the _ownedItems array.
    * @param from address representing the previous owner of the given item ID
    * @param itemId uint256 ID of the item to be removed from the items list of the given address
    */
    function _removeItemFromOwnerEnumeration(
        address from,
        uint256 itemId,
        uint256 layer
    ) private {
        // To prevent a gap in from's items array, we store the last item in the index of the item to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastItemIndex = _ownedItems[layer][from].length.sub(1);
        uint256 itemIndex = _ownedItemsIndex[layer][itemId];

        // When the item to delete is the last item, the swap operation is unnecessary
        if (itemIndex != lastItemIndex) {
            uint256 lastItemId = _ownedItems[layer][from][lastItemIndex];

            _ownedItems[layer][from][itemIndex] = lastItemId; // Move the last item to the slot of the to-delete item
            _ownedItemsIndex[layer][lastItemId] = itemIndex; // Update the moved item's index
        }

        // This also deletes the contents at the last position of the array
        _ownedItems[layer][from].length--;

        // Note that _ownedItemsIndex[itemId] hasn't been cleared: it still points to the old slot (now occupied by
        // lastItemId, or just over the end of the array if the item was the last one).

    }

    /**
    * @dev Private function to remove a item from this extension's item tracking data structures.
    * This has O(1) time complexity, but alters the order of the _allItems array.
    * @param itemId uint256 ID of the item to be removed from the items list
    */
    function _removeItemFromAllItemsEnumeration(uint256 itemId) private {
        // To prevent a gap in the items array, we store the last item in the index of the item to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastItemIndex = _allItems.length.sub(1);
        uint256 itemIndex = _allItemsIndex[itemId];

        // When the item to delete is the last item, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted item is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeItemFromOwnerEnumeration)
        uint256 lastItemId = _allItems[lastItemIndex];

        _allItems[itemIndex] = lastItemId; // Move the last item to the slot of the to-delete item
        _allItemsIndex[lastItemId] = itemIndex; // Update the moved item's index

        // This also deletes the contents at the last position of the array
        _allItems.length--;
        _allItemsIndex[itemId] = 0;
    }
}
