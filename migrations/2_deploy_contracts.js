var ERCXTEST = artifacts.require("ERCXTEST");

module.exports = function (deployer) {
  deployer.deploy(ERCXTEST, "TEST", "TST", "1");
};
