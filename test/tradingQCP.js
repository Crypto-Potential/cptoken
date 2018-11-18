const TradingQCP = artifacts.require('./TradingQCP.sol');
const QCPToken = artifacts.require('./QCPToken.sol');

const promisify = (inner) =>
  new Promise((resolve, reject) =>
    inner((error, result) => {
    if (error) { 
      reject(error) 
    }
    resolve(result);
  })
);

const proxiedWeb3Handler = {
  // override getter                               
  get: (target, name) => {              
    const inner = target[name];                            
    if (inner instanceof Function) {                       
      // Return a function with the callback already set.  
      return (...args) => promisify(cb => inner(...args, cb));                                                         
    } else if (typeof inner === 'object') {                
      // wrap inner web3 stuff                             
      return new Proxy(inner, proxiedWeb3Handler);         
    } else {                                               
      return inner;                                        
    }                                                      
  },                                                       
};
const proxiedWeb3 = new Proxy(web3, proxiedWeb3Handler);


contract('TradingQCP', async(accounts) => {
  let instance
  let owner = accounts[0]
  let account = accounts[1]

  beforeEach(async () => {
    instance = await TradingQCP.deployed()
    token = await QCPToken.deployed()
  })

  it("should buy token correctly", async () => {
    // Set the prices
    let buyPrice = web3.toWei(0.1)
    let sellPrice = web3.toWei(0.09)
    await instance.setPrices(sellPrice, buyPrice, {from: owner})

    // Buy the token
    await instance.buy({from: account, value: web3.toWei(1)})

    let newBalance = await token.balanceOf(account);
    const supplyBalance = await token.getTokenBalance();
    const ethBalance = await instance.getBalance()
    // const instBalance = await token.balanceOf(instance)
    console.log(newBalance,', ',supplyBalance,', ',ethBalance)
    // console.log(instBalance)
    assert.equal(newBalance, 10, "Amount wasn't correctly sent to the receiver");
    // assert.equal(supplyBalance, 1800000000*10**2 - 10, "Amount wasn't correctly deducted from the reciever");
    assert.equal(ethBalance, web3.toWei(1), "Ether balance not proper in the account")
  });

  it("should withdraw ether correctly", async () => {
    // Check Initial balance
    const ownerOldETHBalance = await proxiedWeb3.eth.getBalance(owner);
    const initialBalance = Number(ownerOldETHBalance)
    const gasPrice = web3.toWei(100,'gwei');
    const tokenBalance = await token.getBalance();
    console.log('Withdrawing', tokenBalance)
    // Withdraw ether
    const withdrawAmount = web3.toWei(0.004)
    let txnReceipt = await token.withdraw(withdrawAmount, {from: owner, gasPrice: gasPrice})
    // Calculate gas cost
    const gasUsed = txnReceipt.receipt.gasUsed
    const totgasCost = gasUsed * gasPrice;
    console.log('Withdrawing3')
    // Check Final Balance in the owner and contract account
    const ethBalance = await token.getBalance()   // contract account balance
    const ownerETHBalance = await proxiedWeb3.eth.getBalance(owner); 
    const finalBalance = Number(ownerETHBalance)

    console.log('EtherBalanceFinal: ',finalBalance,', Old:', initialBalance, ', A:', Number(withdrawAmount))
    assert.equal(ethBalance, web3.toWei(0.6), "Ether balance not proper in the contract account")
    assert.equal(finalBalance, initialBalance + Number(withdrawAmount) - totgasCost, "Ether balance not proper in the owner account")
  });

});