pragma solidity ^0.5.0;

import "./ERCXMetadata.sol";
import "../Interface/IERCXSignApproval.sol";


contract ERCXSignApproval is ERCXMetadata, IERCXSignApproval {
    /**
     * @dev Parameters
     */
    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant APPROVE_TYPEHASH = keccak256(
        "SignApprovalForAll(address from,address to,bool approved,uint256 deadline,uint256 nonce)"
    );

    // Mapping from item ID to contract address of TenantRight
    mapping(address => uint256) public nonces;

    /**
     * @dev Constructor function
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory version
    ) public ERCXMetadata(name, symbol) {
        uint256 chainId;
        assembly {
            chainId := chainid
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
    }

    /**
     * @dev Sets or unsets the approval of a given operator with a signature.
     * An operator is allowed to transfer all items of the sender on their behalf
     * @param from user address to set the approval
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     * @param deadline the signature expires after deadline
     * @param v representing a part of the signature
     * @param r representing a part of the signature
     * @param s representing a part of the signature
     */
    function signApprovalForAll(
        address from,
        address to,
        bool approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline == 0 || now <= deadline);
        require(to != from && from != address(0));

        bytes32 hash = keccak256(
            abi.encode(from, to, approved, deadline, nonces[from]++)
        );
        bytes32 prefixed = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );

        require(from == ecrecover(prefixed, v, r, s));

        _approveForAll(from, to, approved);
        emit ApprovalForAll(from, to, approved);
    }
}
