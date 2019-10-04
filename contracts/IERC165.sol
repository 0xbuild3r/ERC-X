pragma solidity ^0.5.0;

interface IERC165 {

  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
}