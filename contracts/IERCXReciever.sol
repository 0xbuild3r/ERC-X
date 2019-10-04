pragma solidity ^0.5.0;


contract IERCXReceiver {

  function onERCXOwnershipReceived(
    address operator,
    address from,
    uint256 tokenId,
    bytes memory data
  )
    public
    returns(bytes4);

  function onERCXSuperOwnershipReceived(
    address operator,
    address from,
    uint256 tokenId,
    bytes memory data
  )
    public
    returns(bytes4);

  function onERCXHyperOwnershipReceived(
    address operator,
    address from,
    uint256 tokenId,
    bytes memory data
  )
    public
    returns(bytes4);

}
