
pragma solidity ^0.5.0;

import '../introspection/ERC165.sol';
import './IERCX.sol';
import '../utils/Address.sol';
import '../math/SafeMath.sol';
import './IERCXReceiver.sol';

contract ERCX is ERC165, IERCX {

  using SafeMath for uint256;
  using Address for address;

  bytes4 private constant _ERCX_RECEIVED = bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"));

  // Mapping from token ID to owner
  mapping (uint256 => address) private _owner;
  mapping (uint256 => address) private _superOwner;
  mapping (uint256 => address) private _hyperOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) private _ownerApprovals;
  mapping (uint256 => address) private _superOwnerApprovals;
  mapping (uint256 => address) private _hyperOwnerApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) private _ownershipTokensCount;
  mapping (address => uint256) private _superOwnershipTokensCount;
  mapping (address => uint256) private _hyperOwnershipTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) private _operatorApprovals;

  bytes4 private constant _InterfaceId_ERCX = 
      bytes4(keccak256('balanceOfOwnerships(address)')) ^
      bytes4(keccak256('balanceOfSuperOwnerships(address)')) ^
      bytes4(keccak256('balanceOfHyperOwnerships(address)')) ^
      bytes4(keccak256('ownerOf(uint256)')) ^
      bytes4(keccak256('superOwnerOf(uint256)')) ^
      bytes4(keccak256('hyperOwnerOf(uint256)')) ^
      bytes4(keccak256('approveOwnershipTransfer(address,uint256)')) ^
      bytes4(keccak256('approveSuperOwnershipTransfer(address,uint256)')) ^
      bytes4(keccak256('approveHyperOwnershipTransfer(address,uint256)')) ^
      bytes4(keccak256('getApprovedAddressForOwnershipTransfer(uint256)')) ^
      bytes4(keccak256('getApprovedAddressForSuperOwnershipTransfer(uint256)')) ^
      bytes4(keccak256('getApprovedAddressForHyperOwnershipTransfer(uint256)')) ^
      bytes4(keccak256('setApprovalForAll(address,bool)')) ^
      bytes4(keccak256('isApprovedForAll(address,address)')) ^
      bytes4(keccak256('transferOwnershipFrom(address,address,uint256)')) ^
      bytes4(keccak256('transferSuperOwnershipFrom(address,address,uint256)')) ^
      bytes4(keccak256('transferHyperOwnershipFrom(address,address,uint256)')) ^
      bytes4(keccak256('safeTransferOwnershipFrom(address,address,uint256)')) ^
      bytes4(keccak256('safeTransferSuperOwnershipFrom(address,address,uint256)')) ^
      bytes4(keccak256('safeTransferHyperOwnershipFrom(address,address,uint256)')) ^
      bytes4(keccak256('safeTransferOwnershipFrom(address,address,uint256,bytes)')) ^
      bytes4(keccak256('safeTransferSuperOwnershipFrom(address,address,uint256,bytes)')) ^
      bytes4(keccak256('safeTransferHyperOwnershipFrom(address,address,uint256,bytes)'));
   

  constructor()
    public
  {
    // register the supported interfaces to conform to ERCX via ERC165
    _registerInterface(_InterfaceId_ERCX);
  }

  /**
   * @dev Gets the balance of the specified address
   * @param user address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOfOwnerships(address user) public view returns (uint256) {
    require(user != address(0));
    uint256 balance = _ownershipTokensCount[user];
    return balance;
  }

  function balanceOfSuperOwnerships(address user) public view returns (uint256) {
    require(user != address(0));
    uint256 balance = _superOwnershipTokensCount[user];
    return balance;
  }

  function balanceOfHyperOwnerships(address user) public view returns (uint256) {
    require(user != address(0));
    uint256 balance = _hyperOwnershipTokensCount[user];
    return balance;
  }

  /**
   * @dev Gets the owner of the specified token ID
   * @param itemId uint256 ID of the token to query the owner of
   * @return owner address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 itemId) public view returns (address) {
    address owner = _owner[itemId];
    require(owner != address(0));
    return owner;
  }

  function superOwnerOf(uint256 itemId) public view returns (address) {
    address superOwner = _superOwner[itemId];
    require(superOwner != address(0));
    return superOwner;
  }

  function hyperOwnerOf(uint256 itemId) public view returns (address) {
    address hyperOwner = _hyperOwner[itemId];
    require(hyperOwner != address(0));
    return hyperOwner;
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param to address to be approved for the given token ID
   * @param itemId uint256 ID of the token to be approved
   */
  function approveOwnershipTransfer(address to, uint256 itemId) public {
    address owner = ownerOf(itemId);
    require(to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    _ownerApprovals[itemId] = to;
    emit ApprovalOwnershipTransfer(owner, to, itemId);
  }

  function approveSuperOwnershipTransfer(address to, uint256 itemId) public {
    address superOwner = superOwnerOf(itemId);
    require(to != superOwner);
    require(msg.sender == superOwner || isApprovedForAll(superOwner, msg.sender));

    _superOwnerApprovals[itemId] = to;
    emit ApprovalSuperOwnershipTransfer(superOwner, to, itemId);
  }

  function approveHyperOwnershipTransfer(address to, uint256 itemId) public {
    address hyperOwner = hyperOwnerOf(itemId);
    require(to != hyperOwner);
    require(msg.sender == hyperOwner || isApprovedForAll(hyperOwner, msg.sender));

    _hyperOwnerApprovals[itemId] = to;
    emit ApprovalHyperOwnershipTransfer(hyperOwner, to, itemId);
  }


  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * Reverts if the token ID does not exist.
   * @param itemId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApprovedAddressForOwnershipTransfer(uint256 itemId) public view returns (address) {
    require(_isItemExists(itemId));
    return _ownerApprovals[itemId];
  }

  function getApprovedAddressForSuperOwnershipTransfer(uint256 itemId) public view returns (address) {
    require(_isItemExists(itemId));
    return _superOwnerApprovals[itemId];
  }

  function getApprovedAddressForHyperOwnershipTransfer(uint256 itemId) public view returns (address) {
    require(_isItemExists(itemId));
    return _hyperOwnerApprovals[itemId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all tokens of the sender on their behalf
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
   * @param author author address which you want to query the approval of
   * @param operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(
    address author,
    address operator
  )
    public
    view
    returns (bool)
  {
    return _operatorApprovals[author][operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param itemId uint256 ID of the token to be transferred
  */
  function transferOwnershipFrom(
    address from,
    address to,
    uint256 itemId
  )
    public
  {
    require(_isAuthorizedToTransferOwnership(msg.sender, itemId));
    require(to != address(0));

    _clearApprovalOfOwnershipTransfer(from, itemId);
    _removeOwnershipFrom(from, itemId);
    _addOwnershipTo(to, itemId);

    emit OwnershipTransferred(from, to, itemId);
  }

  function transferSuperOwnershipFrom(
    address from,
    address to,
    uint256 itemId
  )
    public
  {
    require(_isAuthorizedToTransferSuperOwnership(msg.sender, itemId));
    require(to != address(0));

    _clearApprovalOfSuperOwnershipTransfer(from, itemId);
    _removeSuperOwnershipFrom(from, itemId);
    _addSuperOwnershipTo(to, itemId);

    emit SuperOwnershipTransferred(from, to, itemId);
  }

  function transferHyperOwnershipFrom(
    address from,
    address to,
    uint256 itemId
  )
    public
  {
    require(_isAuthorizedToTransferHyperOwnership(msg.sender, itemId));
    require(to != address(0));

    _clearApprovalOfHyperOwnershipTransfer(from, itemId);
    _removeHyperOwnershipFrom(from, itemId);
    _addHyperOwnershipTo(to, itemId);

    emit HyperOwnershipTransferred(from, to, itemId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERCXReceived`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   *
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param itemId uint256 ID of the token to be transferred
  */
  function safeTransferOwnershipFrom(
    address from,
    address to,
    uint256 itemId
  )
    public
  {
    // solium-disable-next-line arg-overflow
    safeTransferOwnershipFrom(from, to, itemId, "");
  }

  function safeTransferSuperOwnershipFrom(
    address from,
    address to,
    uint256 itemId
  )
    public
  {
    // solium-disable-next-line arg-overflow
    safeTransferSuperOwnershipFrom(from, to, itemId, "");
  }

  function safeTransferHyperOwnershipFrom(
    address from,
    address to,
    uint256 itemId
  )
    public
  {
    // solium-disable-next-line arg-overflow
    safeTransferHyperOwnershipFrom(from, to, itemId, "");
  }


  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERCXReceived`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERCXReceived(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param itemId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function safeTransferOwnershipFrom(
    address from,
    address to,
    uint256 itemId,
    bytes memory _data
  )
    public
  {
    transferOwnershipFrom(from, to, itemId);
    // solium-disable-next-line arg-overflow
    require(_checkAndCallSafeTransfer(from, to, itemId, _data));
  }

  function safeTransferSuperOwnershipFrom(
    address from,
    address to,
    uint256 itemId,
    bytes memory _data
  )
    public
  {
    transferSuperOwnershipFrom(from, to, itemId);
    // solium-disable-next-line arg-overflow
    require(_checkAndCallSafeTransfer(from, to, itemId, _data));
  }

  function safeTransferHyperOwnershipFrom(
    address from,
    address to,
    uint256 itemId,
    bytes memory _data
  )
    public
  {
    transferHyperOwnershipFrom(from, to, itemId);
    // solium-disable-next-line arg-overflow
    require(_checkAndCallSafeTransfer(from, to, itemId, _data));
  }


  /**
   * @dev Returns whether the specified token exists
   * @param itemId uint256 ID of the token to query the existence of
   * @return whether the token exists
   */
  function _isItemExists(uint256 itemId) internal view returns (bool) {
    address owner = _owner[itemId];
    return owner != address(0);
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param spender address of the spender to query
   * @param itemId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token
   */
  function _isAuthorizedToTransferOwnership(
    address spender,
    uint256 itemId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(itemId);
    address superOwner = superOwnerOf(itemId);
    // Disable solium check because of
    // https://github.com/duaraghav8/Solium/issues/175
    // solium-disable-next-line operator-whitespace
    return (
      spender == owner ||
      getApprovedAddressForOwnershipTransfer(itemId) == spender ||
      isApprovedForAll(owner, spender) ||
      spender == superOwner
    );
  }

    function _isAuthorizedToTransferSuperOwnership(
    address spender,
    uint256 itemId
  )
    internal
    view
    returns (bool)
  {
    address superOwner = superOwnerOf(itemId);
    address hyperOwner = hyperOwnerOf(itemId);
    
    // Disable solium check because of
    // https://github.com/duaraghav8/Solium/issues/175
    // solium-disable-next-line operator-whitespace
    return (
      spender == superOwner ||
      getApprovedAddressForSuperOwnershipTransfer(itemId) == spender ||
      isApprovedForAll(superOwner, spender) ||
      spender == hyperOwner
    );
  }

  function _isAuthorizedToTransferHyperOwnership(
    address spender,
    uint256 itemId
  )
    internal
    view
    returns (bool)
  {
    address hyperOwner = hyperOwnerOf(itemId);
    
    // Disable solium check because of
    // https://github.com/duaraghav8/Solium/issues/175
    // solium-disable-next-line operator-whitespace
    return (
      spender == hyperOwner ||
      getApprovedAddressForHyperOwnershipTransfer(itemId) == spender ||
      isApprovedForAll(hyperOwner, spender) 
    );
  }



  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
   * @param to The address that will own the minted token
   * @param itemId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address to, uint256 itemId) internal {
    require(to != address(0));
    _addOwnershipTo(to, itemId);
    _addSuperOwnershipTo(to, itemId);
    _addHyperOwnershipTo(to, itemId);
    emit OwnershipTransferred(address(0), to, itemId);
    emit SuperOwnershipTransferred(address(0), to, itemId);
    emit HyperOwnershipTransferred(address(0), to, itemId);
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param itemId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address owner, uint256 itemId) internal {
    _clearApprovalOfOwnershipTransfer(owner, itemId);
    _clearApprovalOfSuperOwnershipTransfer(owner, itemId);
    _clearApprovalOfHyperOwnershipTransfer(owner, itemId);
    _removeOwnershipFrom(owner, itemId);
    _removeSuperOwnershipFrom(owner, itemId);
    _removeHyperOwnershipFrom(owner, itemId);
    emit OwnershipTransferred(owner, address(0), itemId);
    emit SuperOwnershipTransferred(owner, address(0), itemId);
    emit HyperOwnershipTransferred(owner, address(0), itemId);
  }

  /**
   * @dev Internal function to clear current approval of a given token ID
   * Reverts if the given address is not indeed the owner of the token
   * @param owner owner of the token
   * @param itemId uint256 ID of the token to be transferred
   */
  function _clearApprovalOfOwnershipTransfer(address owner, uint256 itemId) internal {
    require(ownerOf(itemId) == owner);
    if (_ownerApprovals[itemId] != address(0)) {
      _ownerApprovals[itemId] = address(0);
    }
  }

  function _clearApprovalOfSuperOwnershipTransfer(address superOwner, uint256 itemId) internal {
    require(superOwnerOf(itemId) == superOwner);
    if (_superOwnerApprovals[itemId] != address(0)) {
      _superOwnerApprovals[itemId] = address(0);
    }
  }

  function _clearApprovalOfHyperOwnershipTransfer(address hyperOwner, uint256 itemId) internal {
    require(hyperOwnerOf(itemId) == hyperOwner);
    if (_hyperOwnerApprovals[itemId] != address(0)) {
      _hyperOwnerApprovals[itemId] = address(0);
    }
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param to address representing the new owner of the given token ID
   * @param itemId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addOwnershipTo(address to, uint256 itemId) internal {
    require(_owner[itemId] == address(0));
    _owner[itemId] = to;
    _ownershipTokensCount[to] = _ownershipTokensCount[to].add(1);
  }

  function _addSuperOwnershipTo(address to, uint256 itemId) internal {
    require(_superOwner[itemId] == address(0));
    _superOwner[itemId] = to;
    _superOwnershipTokensCount[to] = _superOwnershipTokensCount[to].add(1);
  }

  function _addHyperOwnershipTo(address to, uint256 itemId) internal {
    require(_hyperOwner[itemId] == address(0));
    _hyperOwner[itemId] = to;
    _hyperOwnershipTokensCount[to] = _hyperOwnershipTokensCount[to].add(1);
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param from address representing the previous owner of the given token ID
   * @param itemId uint256 ID of the token to be removed from the tokens list of the given address
   */

  function _removeOwnershipFrom(address from, uint256 itemId) internal {
    require(ownerOf(itemId) == from);
    _ownershipTokensCount[from] = _ownershipTokensCount[from].sub(1);
    _owner[itemId] = address(0);
  }

  function _removeSuperOwnershipFrom(address from, uint256 itemId) internal {
    require(superOwnerOf(itemId) == from);
    _superOwnershipTokensCount[from] = _superOwnershipTokensCount[from].sub(1);
    _superOwner[itemId] = address(0);
  }
 
  function _removeHyperOwnershipFrom(address from, uint256 itemId) internal {
    require(hyperOwnerOf(itemId) == from);
    _hyperOwnershipTokensCount[from] = _hyperOwnershipTokensCount[from].sub(1);
    _hyperOwner[itemId] = address(0);
  }


  /**
   * @dev Internal function to invoke `onERCXReceived` on a target address
   * The call is not executed if the target address is not a contract
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param itemId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function _checkAndCallSafeTransfer(
    address from,
    address to,
    uint256 itemId,
    bytes memory _data
  )
    internal
    returns (bool)
  {
    if (!to.isContract()) {
      return true;
    }
    bytes4 retval = IERCXReceiver(to).onERCXReceived(
      msg.sender, from, itemId, _data);
    return (retval == _ERCX_RECEIVED);
  }
  
}


