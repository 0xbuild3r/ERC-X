pragma solidity ^0.5.0;

import "../../Libraries/introspection/IERC165.sol";

contract IERCX is IERC165 {
    event TransferUser(
        address indexed from,
        address indexed to,
        uint256 indexed itemId,
        address operator
    );
    event ApprovalForUser(
        address indexed user,
        address indexed approved,
        uint256 itemId
    );
    event TransferOwner(
        address indexed from,
        address indexed to,
        uint256 indexed itemId,
        address operator
    );
    event ApprovalForOwner(
        address indexed owner,
        address indexed approved,
        uint256 itemId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event LienApproval(address indexed to, uint256 indexed itemId);
    event TenantRightApproval(address indexed to, uint256 indexed itemId);
    event LienSet(address indexed to, uint256 indexed itemId, bool status);
    event TenantRightSet(
        address indexed to,
        uint256 indexed itemId,
        bool status
    );

    function balanceOfOwner(address owner) public view returns (uint256);

    function balanceOfUser(address user) public view returns (uint256);

    function userOf(uint256 itemId) public view returns (address);

    function ownerOf(uint256 itemId) public view returns (address);

    function safeTransferOwner(address from, address to, uint256 itemId) public;
    function safeTransferOwner(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) public;

    function safeTransferUser(address from, address to, uint256 itemId) public;
    function safeTransferUser(
        address from,
        address to,
        uint256 itemId,
        bytes memory data
    ) public;

    function approveForOwner(address to, uint256 itemId) public;
    function getApprovedForOwner(uint256 itemId) public view returns (address);

    function approveForUser(address to, uint256 itemId) public;
    function getApprovedForUser(uint256 itemId) public view returns (address);

    function setApprovalForAll(address operator, bool approved) public;
    function isApprovedForAll(address requester, address operator)
        public
        view
        returns (bool);

    function approveLien(address to, uint256 itemId) public;
    function getApprovedLien(uint256 itemId) public view returns (address);
    function setLien(uint256 itemId) public;
    function getCurrentLien(uint256 itemId) public view returns (address);
    function revokeLien(uint256 itemId) public;

    function approveTenantRight(address to, uint256 itemId) public;
    function getApprovedTenantRight(uint256 itemId)
        public
        view
        returns (address);
    function setTenantRight(uint256 itemId) public;
    function getCurrentTenantRight(uint256 itemId)
        public
        view
        returns (address);
    function revokeTenantRight(uint256 itemId) public;
}
