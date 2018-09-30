var SafeMath = artifacts.require("./library/SafeMath.sol");
var QCPToken = artifacts.require("./token/QCPToken.sol");

module.exports = function(deployer) {
  deployer.deploy(SafeMath);
  deployer.link(SafeMath, QCPToken);
  deployer.deploy(QCPToken);
};
