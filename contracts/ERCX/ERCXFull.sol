
pragma solidity ^0.5.0;

import './ERCXEnumerable.sol';
import './ERCXMetadata.sol';

contract ERCXFull is ERCX, ERCXEnumerable, ERCXMetadata {
  constructor(string memory name, string memory symbol) ERCXMetadata(name, symbol)
    public
  {
  }
}


