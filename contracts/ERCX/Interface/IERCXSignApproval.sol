pragma solidity ^0.5.0;

import "./IERCXMetadata.sol";

contract IERCXSignApproval is IERCXMetadata {
    function signApprovalForAll(
        address from,
        address to,
        bool approved,
        uint256 deadline,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
