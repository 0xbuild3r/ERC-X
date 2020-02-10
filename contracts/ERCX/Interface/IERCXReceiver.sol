pragma solidity ^0.5.0;

/**
 * @title ERCX token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERCX asset contracts.
 */
contract IERCXReceiver {
    /**
    * @notice Handle the receipt of an NFT
    * @dev The ERCX smart contract calls this function on the recipient
    * after a {IERCX-safeTransferFrom}. This function MUST return the function selector,
    * otherwise the caller will revert the transaction. The selector to be
    * returned can be obtained as `this.onERCXReceived.selector`. This
    * function MAY throw to revert and reject the transfer.
    * Note: the ERCX contract address is always the message sender.
    * @param operator The address which called `safeTransferFrom` function
    * @param from The address which previously owned the token
    * @param itemId The NFT identifier which is being transferred
    * @param data Additional data with no specified format
    * @return bytes4 `bytes4(keccak256("onERCXReceived(address,address,uint256,uint256,bytes)"))`
    */
    function onERCXReceived(
        address operator,
        address from,
        uint256 itemId,
        uint256 layer,
        bytes memory data
    ) public returns (bytes4);
}
