pragma solidity ^0.5.0;

import "./MinterRole.sol";
import "./ERCXFull.sol";


contract ERCXMintable is ERCXFull, MinterRole {
    event MintingFinished();

    bool private _mintingFinished = false;

    modifier onlyBeforeMintingFinished() {
        require(!_mintingFinished);
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory version
    ) public ERCXFull(name, symbol, version) {}

    /**
     * @return true if the minting is finished.
     */
    function mintingFinished() public view returns (bool) {
        return _mintingFinished;
    }

    /**
     * @dev Function to mint items
     * @param to The address that will receive the minted items.
     * @param itemId The item id to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 itemId)
        public
        onlyMinter
        onlyBeforeMintingFinished
        returns (bool)
    {
        _mint(to, itemId);
        return true;
    }

    function mintWithItemURI(
        address to,
        uint256 itemId,
        string memory itemURI
    ) public onlyMinter onlyBeforeMintingFinished returns (bool) {
        mint(to, itemId);
        _setItemURI(itemId, itemURI);
        return true;
    }

    /**
     * @dev Function to stop minting new items.
     * @return True if the operation was successful.
     */
    function finishMinting()
        public
        onlyMinter
        onlyBeforeMintingFinished
        returns (bool)
    {
        _mintingFinished = true;
        emit MintingFinished();
        return true;
    }
}
