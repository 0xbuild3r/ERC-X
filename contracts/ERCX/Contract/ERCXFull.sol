
pragma solidity ^0.5.0;

import './ERCX.sol';
import './ERCXEnumerable.sol';
import './ERCXMetadata.sol';
import './ERCX721fier.sol';


contract ERCXFull is ERCX, ERCXEnumerable, ERCXMetadata, ERCX721fier {
  constructor(string memory name, string memory symbol) ERCXMetadata(name, symbol)
    public
  {
  }
}

