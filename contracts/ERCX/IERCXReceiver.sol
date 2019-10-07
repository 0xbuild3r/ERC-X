pragma solidity ^0.5.0;


contract IERCXReceiver {

  function onERCXReceived(
    address operator,
    address from,
    uint256 itemId,
    bytes memory data
  )
    public
    returns(bytes4);

}
