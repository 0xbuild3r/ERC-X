
pragma solidity ^0.5.0;


import './ERCXMintable.sol';


contract Sample is ERCXMintable {

    uint16 public constant EXTENSION_TYPE_OFFSET = 10000;

    string public tokenURIPrefix = "https://www.mycryptoheroes.net/metadata/extension/";
    mapping(uint16 => uint16) private extensionTypeToSupplyLimit;

    constructor() public ERC721Full("MyCryptoHeroes:Extension", "MCHE") {
    }

    function isAlreadyMinted(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function setSupplyLimit(uint16 _extensionType, uint16 _supplyLimit) external onlyMinter {
        require(_supplyLimit != 0);
        require(extensionTypeToSupplyLimit[_extensionType] == 0 || _supplyLimit < extensionTypeToSupplyLimit[_extensionType],
            "_supplyLimit is bigger");
        extensionTypeToSupplyLimit[_extensionType] = _supplyLimit;
    }

    function setTokenURIPrefix(string _tokenURIPrefix) external onlyMinter {
        tokenURIPrefix = _tokenURIPrefix;
    }

    function getSupplyLimit(uint16 _extensionType) public view returns (uint16) {
        return extensionTypeToSupplyLimit[_extensionType];
    }

    function mintExtensionAsset(address _owner, uint256 _tokenId) public onlyMinter {
        uint16 _extensionType = uint16(_tokenId / EXTENSION_TYPE_OFFSET);
        uint16 _extensionTypeIndex = uint16(_tokenId % EXTENSION_TYPE_OFFSET) - 1;
        require(_extensionTypeIndex < extensionTypeToSupplyLimit[_extensionType], "supply over");
        _mint(_owner, _tokenId);
    }

    function tokenURI(uint256 tokenId) public view returns (string) {
        bytes32 tokenIdBytes;
        if (tokenId == 0) {
            tokenIdBytes = "0";
        } else {
            uint256 value = tokenId;
            while (value > 0) {
                tokenIdBytes = bytes32(uint256(tokenIdBytes) / (2 ** 8));
                tokenIdBytes |= bytes32(((value % 10) + 48) * 2 ** (8 * 31));
                value /= 10;
            }
        }

        bytes memory prefixBytes = bytes(tokenURIPrefix);
        bytes memory tokenURIBytes = new bytes(prefixBytes.length + tokenIdBytes.length);

        uint8 i;
        uint8 index = 0;
        
        for (i = 0; i < prefixBytes.length; i++) {
            tokenURIBytes[index] = prefixBytes[i];
            index++;
        }
        
        for (i = 0; i < tokenIdBytes.length; i++) {
            tokenURIBytes[index] = tokenIdBytes[i];
            index++;
        }
        
        return string(tokenURIBytes);
    }

}