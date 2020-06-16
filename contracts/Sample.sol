pragma solidity ^0.5.0;

import "./ERCX/Contract/ERCXMintable.sol";


contract Sample is ERCXMintable {
    constructor(
        string memory name,
        string memory symbol,
        string memory version
    ) public ERCXMintable(name, symbol, version) {}
}
