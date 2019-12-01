var ERCXMintable = artifacts.require("./ERCXMintable.sol");

module.exports = function(deployer) {
  deployer.deploy(ERCXMintable, "TEST", "TST");
};
