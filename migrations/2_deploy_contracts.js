var ERCXFull = artifacts.require("./ERCXFullmock.sol");

module.exports = function(deployer) {
  deployer.deploy(ERCXFull, "TEST", "TST");
};
