
pragma solidity ^0.5.0;

import '../../Libraries/introspection/ERC165.sol';
import '../Interface/IERCX.sol';
import '../../Libraries/utils/Address.sol';
import '../../Libraries/math/SafeMath.sol';
import "../../Libraries/drafts/Counters.sol";
import '../Interface/IERCXReceiver.sol';

contract ERCX is ERC165, IERCX {

  using SafeMath for uint256;
  using Address for address;
  using Counters for Counters.Counter;

  bytes4 private constant _ERCX_RECEIVED = bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"));

  // Mapping from item ID to layer to owner
  mapping (uint256 => mapping (uint256 => address)) private _itemOwner;

  // Mapping from item ID to layer to approved address
  mapping (uint256 => mapping (uint256 => address)) private _transferApprovals;

  // Mapping from owner to layer to number of owned item
  mapping (address => mapping(uint256 => Counters.Counter)) private _ownedItemsCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) private _operatorApprovals;

  // Mapping from item ID to layer to approved address of suspension
  mapping (uint256 => mapping (uint256 => address)) private _transferLimitApprovals;

  // Mapping from item iD to layer to transferrable status
  mapping (uint256 => mapping (uint256 => bool)) private _transferLimitStatus;

  // Mapping from item id to layer to limitter address
  mapping (uint256 => mapping (uint256 => address)) private _transferLimitters;

  bytes4 private constant _InterfaceId_ERCX = 
    bytes4(keccak256("balanceOf(address, uint256)")) ^
    bytes4(keccak256("ownerOf(uint256, uint256)")) ^
    bytes4(keccak256("superOf(uint256, uint256)")) ^
    bytes4(keccak256("safeTransferFrom(address, address, uint256, uint256)")) ^
    bytes4(keccak256("safeTransferFrom(address, address, uint256, uint256, bytes)")) ^
    bytes4(keccak256("approveTransfer(address, uint256, uint256)")) ^
    bytes4(keccak256("getApprovedTransfer(uint256, uint256)")) ^
    bytes4(keccak256("setApprovalForAll(address, bool)")) ^
    bytes4(keccak256("isApprovedForAll(address, address)")) ^
    bytes4(keccak256("approveTransferLimitFor(address, uint256, uint256)")) ^
    bytes4(keccak256("getApprovedTransferLimit(uint256, uint256)")) ^
    bytes4(keccak256("setTransferLimitFor(uint256, uint256)")) ^
    bytes4(keccak256("revokeTransferLimitFor(uint256, uint256)"));

  constructor()
    public
  {
    // register the supported interfaces to conform to ERCX via ERC165
    _registerInterface(_InterfaceId_ERCX);
  }

  /**
   * @dev Gets the balance of the specified address
   * @param owner address to query the balance of
   * @param layer uint256 number to specify the layer
   * @return uint256 representing the amount of items owned by the passed address in the specified layer
   */
  function balanceOf(address owner, uint256 layer) public view returns (uint256) {
    require(owner != address(0));
    uint256 balance = _ownedItemsCount[owner][layer].current();
    return balance;
  }

  /**
   * @dev Gets the owner of the specified item ID
   * @param itemId uint256 ID of the item to query the owner of
   * @param layer uint256 number to specify the layer
   * @return owner address currently marked as the owner of the given item ID in the specified layer
   */
  function ownerOf(uint256 itemId, uint256 layer) public view returns (address) {
    address owner = _itemOwner[itemId][layer];
    require(owner != address(0));
    return owner;
  }

  /**
   * @dev Gets the upper layer address of the owner of the specified item ID
   * @param itemId uint256 ID of the item to query the owner of
   * @param layer uint256 number to specify the layer
   * @return the upper layer address currently marked as the owner of the given item ID in the specified layer
   */
  function superOf(uint256 itemId, uint256 layer) public view returns (address) {
    uint256 upperLayer = layer.add(1);
    address owner = ownerOf(itemId, upperLayer);
    return owner;
  }

  /**
   * @dev Approves another address to transfer the given item ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per item at a given time.
   * Can only be called by the item owner or an approved operator.
   * @param to address to be approved for the given item ID
   * @param itemId uint256 ID of the item to be approved
   * @param layer uint256 number to specify the layer
   */
  function approveTransfer(address to, uint256 itemId, uint256 layer) public {
    
    address owner = ownerOf(itemId, layer);
    require(to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    _transferApprovals[itemId][layer] = to;
    emit ApprovalTransfer(owner, to, itemId, layer);
  }

  /**
   * @dev Gets the approved address for a item ID, or zero if no address set
   * Reverts if the item ID does not exist.
   * @param itemId uint256 ID of the item to query the approval of
   * @param layer uint256 number to specify the layer
   * @return address currently approved for the given item ID
   */
  function getApprovedTransfer(uint256 itemId, uint256 layer) public view returns (address) {
    require(_exists(itemId, layer));
    return _transferApprovals[itemId][layer];
  }

  /**
   * @dev Approves another address to suspend the transfer right of the given item ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per item at a given time.
   * Can only be called by the item owner or an approved operator.
   * @param to address to be approved for the given item ID
   * @param itemId uint256 ID of the item to be approved
   * @param layer uint256 number to specify the layer
   */
  function approveTransferLimitFor(address to, uint256 itemId, uint256 layer) public {
    
    address owner = ownerOf(itemId, layer);
    address so = superOf(itemId, layer);
    require(to != owner || to != so );
    require(msg.sender == owner || msg.sender == so || isApprovedForAll(owner, msg.sender) || isApprovedForAll(so, msg.sender));

    _transferLimitApprovals[itemId][layer] = to;
     emit ApprovalTransferLimit(owner, to, itemId, layer);

  }

  /**
   * @dev Gets the approved address for suspension for transfer a item ID, or zero if no address set
   * Reverts if the item ID does not exist.
   * @param itemId uint256 ID of the item to query the approval of
   * @param layer uint256 number to specify the layer
   * @return address currently approved for the given item ID
   */
  function getApprovedTransferLimit(uint256 itemId, uint256 layer) public view returns (address) {
    require(_exists(itemId, layer));
    return _transferLimitApprovals[itemId][layer];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all items of the sender on their behalf
   * @param to operator address to set the approval
   * @param approved representing the status of the approval to be set
   */
  function setApprovalForAll(address to, bool approved) public {
    require(to != msg.sender);
    _operatorApprovals[msg.sender][to] = approved;
    emit ApprovalForAll(msg.sender, to, approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner
   * @param owner owner address which you want to query the approval of
   * @param operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(address owner, address operator) public view returns (bool){
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev Limit the transferability of the specified item.
   * msg.sender should be permitted by either owner or so(super owner)
   * @param itemId uint256 ID of the item to be transferred
   * @param layer uint256 number to specify the layer
  */
  function setTransferLimitFor(uint256 itemId, uint256 layer) public {
    
    require(_isTransferrable(itemId, layer));
    address owner = ownerOf(itemId, layer);
    address so = superOf(itemId, layer);
    require(msg.sender == getApprovedTransferLimit(itemId, layer) || isApprovedForAll(owner, msg.sender) || isApprovedForAll(so, msg.sender));

    _transferLimitStatus[itemId][layer] = false;
    _transferLimitters[itemId][layer] = msg.sender;
    emit TransferLimitSet(msg.sender, itemId, layer, true);

  }

  /**
   * @dev Revole the limitation of transferability of the specified item.
   *
   * Requires the msg sender to be the setter of the limitation
   * @param itemId uint256 ID of the item to be transferred
   * @param layer uint256 number to specify the layer
  */
  function revokeTransferLimitFor(uint256 itemId, uint256 layer) public {
    
    require(!_isTransferrable(itemId, layer));
    address limitter = _transferLimitters[itemId][layer];
    require(msg.sender == limitter);

    _transferLimitStatus[itemId][layer] = true;
    _transferLimitters[itemId][layer] = address(0);
    emit TransferLimitSet(msg.sender, itemId, layer, false);

  }

  /**
   * @dev Safely transfers the ownership of a given item ID to another address
   * If the target address is a contract, it must implement `onERCXReceived`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   *
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the item
   * @param to address to receive the ownership of the given item ID
   * @param itemId uint256 ID of the item to be transferred
   * @param layer uint256 number to specify the layer
  */
  function safeTransferFrom(
    address from,
    address to,
    uint256 itemId,
    uint256 layer
  )
    public
  {
    // solium-disable-next-line arg-overflow
    safeTransferFrom(from, to, itemId, layer, "");
  }

  /**
   * @dev Safely transfers the ownership of a given item ID to another address
   * If the target address is a contract, it must implement `onERCXReceived`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the item
   * @param to address to receive the ownership of the given item ID
   * @param itemId uint256 ID of the item to be transferred
   * @param layer uint256 number to specify the layer
   * @param data bytes data to send along with a safe transfer check
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 itemId,
    uint256 layer,
    bytes memory data
  )
    public
  {
    require(_isEligibleForTransfer(msg.sender, itemId, layer));
    _safeTransferFrom(from, to, itemId, layer, data);
  }

  /**
    * @dev Safely transfers the ownership of a given item ID to another address
    * If the target address is a contract, it must implement `onERCXReceived`,
    * which is called upon a safe transfer, and return the magic value
    * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
    * the transfer is reverted.
    * Requires the msg.sender to be the owner, approved, or operator
    * @param from current owner of the item
    * @param to address to receive the ownership of the given item ID
    * @param itemId uint256 ID of the item to be transferred
    * @param layer uint256 number to specify the layer
    * @param data bytes data to send along with a safe transfer check
    */
  function _safeTransferFrom(address from, address to, uint256 itemId, uint256 layer, bytes memory data) internal {
      _transferFrom(from, to, itemId, layer);
      require(_checkOnERCXReceived(from, to, itemId, layer, data));
  }

  /**
    * @dev Returns whether the given spender can transfer a given item ID.
    * @param spender address of the spender to query
    * @param itemId uint256 ID of the item to be transferred
    * @param layer uint256 number to specify the layer
    * @return bool whether the msg.sender is approved for the given item ID,
    * is an operator of the owner, or is the owner of the item
    */
  function _isEligibleForTransfer(address spender, uint256 itemId, uint256 layer) internal view returns (bool) {
      require(_exists(itemId, layer));
      address owner = ownerOf(itemId, layer);
      address so = superOf(itemId, layer);
      return (spender == owner || spender == so || getApprovedTransfer(itemId, layer) == spender || isApprovedForAll(owner, spender) || isApprovedForAll(so, spender));
  }

  /**
    * @dev Returns whether the given item can be transferred.
    * @param itemId uint256 ID of the item to be transferred
    * @param layer uint256 number to specify the layer
    * @return bool whether he given item can be transferred.
    */
  function _isTransferrable(uint256 itemId, uint256 layer) internal view returns (bool) {
      require(_exists(itemId, layer), "ERCX: operator query for nonexistent item");
      return _transferLimitStatus[itemId][layer];
  }

  /**
   * @dev Returns whether the specified item exists
   * @param itemId uint256 ID of the item to query the existence of
   * @param layer uint256 number to specify the layer
   * @return whether the item exists
   */
  function _exists(uint256 itemId, uint256 layer) internal view returns (bool) {
    address owner = _itemOwner[itemId][layer];
    return owner != address(0);
  }

  /**
    * @dev Internal function to safely mint a new item.
    * Reverts if the given item ID already exists.
    * If the target address is a contract, it must implement `onERCXReceived`,
    * which is called upon a safe transfer, and return the magic value
    * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
    * the transfer is reverted.
    * @param to The address that will own the minted item
    * @param itemId uint256 ID of the item to be minted
    */
  function _safeMint(address to, uint256 itemId) internal {
      _safeMint(to, itemId, "");
  }

  /**
    * @dev Internal function to safely mint a new item.
    * Reverts if the given item ID already exists.
    * If the target address is a contract, it must implement `onERCXReceived`,
    * which is called upon a safe transfer, and return the magic value
    * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
    * the transfer is reverted.
    * @param to The address that will own the minted item
    * @param itemId uint256 ID of the item to be minted
    * @param data bytes data to send along with a safe transfer check
    */
  function _safeMint(address to, uint256 itemId, bytes memory data) internal {
      _mint(to, itemId);
      require(_checkOnERCXReceived(address(0), to, itemId, 1, data));
      require(_checkOnERCXReceived(address(0), to, itemId, 2, data));
      require(_checkOnERCXReceived(address(0), to, itemId, 3, data));
  }

  /**
    * @dev Internal function to mint a new item.
    * Reverts if the given item ID already exists.
    * A new item iss minted with all three layers.
    * @param to The address that will own the minted item
    * @param itemId uint256 ID of the item to be minted
    */
  function _mint(address to, uint256 itemId) internal {
      require(to != address(0), "ERCX: mint to the zero address");
      require(!_exists(itemId,1), "ERCX: item already minted");

      _itemOwner[itemId][1] = to;
      _itemOwner[itemId][2] = to;
      _itemOwner[itemId][3] = to;
      _ownedItemsCount[to][1].increment();
      _ownedItemsCount[to][2].increment();
      _ownedItemsCount[to][3].increment();

      emit Transfer(msg.sender, address(0), to, itemId,1);
      emit Transfer(msg.sender, address(0), to, itemId,2);
      emit Transfer(msg.sender, address(0), to, itemId,3);
  }

  /**
    * @dev Internal function to burn a specific item.
    * Reverts if the item does not exist.
    * @param itemId uint256 ID of the item being burned
    */
  function _burn(uint256 itemId) internal {
      
    address owner1 = ownerOf(itemId, 1);
    address owner2 = ownerOf(itemId, 2);
    address owner3 = ownerOf(itemId, 3);

      _clearApproval(itemId,1);
      _clearApproval(itemId,2);
      _clearApproval(itemId,3);

      _ownedItemsCount[owner1][1].decrement();
      _ownedItemsCount[owner2][2].decrement();
      _ownedItemsCount[owner3][3].decrement();
      _itemOwner[itemId][1] = address(0);
      _itemOwner[itemId][2] = address(0);
      _itemOwner[itemId][3] = address(0);

      emit Transfer(msg.sender, owner1, address(0), itemId,1);
      emit Transfer(msg.sender, owner2, address(0), itemId,2);
      emit Transfer(msg.sender, owner3, address(0), itemId,3);
  }

  /**
    * @dev Internal function to transfer ownership of a given item ID to another address.
    * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
    * @param from current owner of the item
    * @param to address to receive the ownership of the given item ID
    * @param itemId uint256 ID of the item to be transferred
    * @param layer uint256 number to specify the layer
    */
  function _transferFrom(address from, address to, uint256 itemId, uint256 layer) internal {
      require( ownerOf(itemId,layer) == from );
      require(to != address(0));

      _clearApproval(itemId, layer);

      _ownedItemsCount[from][layer].decrement();
      _ownedItemsCount[to][layer].increment();

      _itemOwner[itemId][layer] = to;

      emit Transfer(msg.sender, from, to, itemId, layer);
  }

  /**
    * @dev Internal function to invoke {IERCXReceiver-onERCXReceived} on a target address.
    * The call is not executed if the target address is not a contract.
    *
    * This is an internal detail of the `ERCX` contract and its use is deprecated.
    * @param from address representing the previous owner of the given item ID
    * @param to target address that will receive the items
    * @param itemId uint256 ID of the item to be transferred
    * @param layer uint256 number to specify the layer
    * @param data bytes optional data to send along with the call
    * @return bool whether the call correctly returned the expected magic value
    */
  function _checkOnERCXReceived(address from, address to, uint256 itemId,uint256 layer, bytes memory data)
      internal returns (bool)
  {
      if (!to.isContract()) {
          return true;
      }

      bytes4 retval = IERCXReceiver(to).onERCXReceived(msg.sender, from, itemId, layer, data);
      return (retval == _ERCX_RECEIVED);
  }

  /**
    * @dev Private function to clear current approval of a given item ID.
    * @param itemId uint256 ID of the item to be transferred
    * @param layer uint256 number to specify the layer
    */
  function _clearApproval(uint256 itemId, uint256 layer) private {
      if (_transferApprovals[itemId][layer] != address(0)) {
          _transferApprovals[itemId][layer] = address(0);
      }
      if (_transferLimitApprovals[itemId][layer] != address(0)) {
          _transferLimitApprovals[itemId][layer] = address(0);
      }
  }

}
