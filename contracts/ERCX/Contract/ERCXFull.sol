pragma solidity ^0.5.0;

import "./ERCX.sol";
import "./ERCXEnumerable.sol";
import "./ERCXSignApproval.sol";
import "./ERCX721fier.sol";


contract ERCXFull is ERCX, ERCXEnumerable, ERCXSignApproval, ERCX721fier {
    constructor(
        string memory name,
        string memory symbol,
        string memory version
    ) public ERCXSignApproval(name, symbol, version) {}
}
