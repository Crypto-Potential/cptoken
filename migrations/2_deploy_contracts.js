var SafeMath = artifacts.require("./library/SafeMath.sol");
var QCPToken = artifacts.require("./token/QCPToken.sol");
var CrowdSaleQCP = artifacts.require("./token/CrowdSaleQCP.sol");
var TradingQCP = artifacts.require("./token/TradingQCP.sol");
// module.exports = function(deployer) {
//   deployer.deploy(SafeMath);
//   deployer.link(SafeMath, QCPToken);
//   deployer.deploy(QCPToken);
  
// };

module.exports = (deployer, network, [owner]) => {
  return deployer
    .then(() => deployer.deploy(QCPToken))
    .then(() => deployer.deploy(CrowdSaleQCP, 10000, owner, QCPToken.address))
    .then(() => deployer.deploy(TradingQCP, QCPToken.address))
    .then(() => QCPToken.deployed())
    .then(token => {
      token.setReleaseAgent(owner, {from: owner})
      // token.setTransferAgent(TradingQCP.address, true, {from: owner})
      token.transfer(TradingQCP.address, 1000*10**2, {from: owner})
    }).then(() => TradingQCP.deployed())
};

// QCPToken.deployed().then(inst => { qcpinstance = inst })
// qcpinstance.getBalance.call()
// qcpinstance.balanceOf(web3.eth.accounts[0]).call()
