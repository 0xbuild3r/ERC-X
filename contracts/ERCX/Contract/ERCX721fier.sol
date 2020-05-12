pragma solidity ^0.5.0;

import "./ERCX.sol";
import "../../Libraries/token/ERC721/IERC721.sol";
import "../../Libraries/token/ERC721/IERC721Receiver.sol";


/**
 * @title ERC721 Non-Fungible Token Standard compatible layer
 * Each items here represents owner of the item set.
 * By implementing this contract set, ERCX can pretend to be an ERC721 contrtact set.
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERCX721fier is ERC165, IERC721, ERCX {
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor() public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balanceOfOwner(owner);
    }

    function ownerOf(uint256 itemId) public view returns (address) {
        return super.ownerOf(itemId);
    }

    function approve(address to, uint256 itemId) public {
        approveForOwner(to, itemId);
        address owner = ownerOf(itemId);
        emit Approval(owner, to, itemId);
    }

    function getApproved(uint256 itemId) public view returns (address) {
        return getApprovedForOwner(itemId);
    }

    function transferFrom(address from, address to, uint256 itemId) public {
        require(_isEligibleForTransfer(msg.sender, itemId, 2));
        if (getCurrentTenantRight(itemId) == address(0)) {
            _transfer(from, to, itemId, 1);
            _transfer(from, to, itemId, 2);
        } else {
            _transfer(from, to, itemId, 2);
        }
        emit Transfer(from, to, itemId);
    }

    function safeTransferFrom(address from, address to, uint256 itemId) public {
        safeTransferFrom(from, to, itemId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) public {
        transferFrom(from, to, itemId);
        require(
            _checkOnERC721Received(from, to, itemId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(
            msg.sender,
            from,
            itemId,
            data
        );
        return (retval == _ERC721_RECEIVED);
    }
}
