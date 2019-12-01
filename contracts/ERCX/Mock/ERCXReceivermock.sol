pragma solidity ^0.5.0;

import "../Interface/IERCXReceiver.sol";

contract ERCXReceiverMock is IERCXReceiver {
    bytes4 private _retval;
    bool private _reverts;

    event Received(address operator, address from, uint256 tokenId, uint256 layer, bytes data, uint256 gas);

    constructor (bytes4 retval, bool reverts) public {
        _retval = retval;
        _reverts = reverts;
    }

    function onERCXReceived(address operator, address from, uint256 tokenId,uint256 layer, bytes memory data)
        public returns (bytes4)
    {
        require(!_reverts, "ERCXReceiverMock: reverting");
        emit Received(operator, from, tokenId, layer, data, gasleft());
        return _retval;
    }
}