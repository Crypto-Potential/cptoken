const QCPToken = artifacts.require('./QCPToken.sol');
const Web3 = require('web3')

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

contract('QCPToken', async(accounts) => {
  let instance
  let owner = accounts[0]
  let account = accounts[1]
  beforeEach(async () => {
    instance = await QCPToken.deployed()
  })

  it("should put 1800000000 QCP in the contract account", async() => {
    const balance = await instance.getTokenBalance();
    console.log('Balance:',balance)
    // assert.equal(balance.valueOf(), 1800000000*10**2);
  })

  // it("should call a function sets the price", async () => {
  //   let buyPrice = web3.toWei(0.1)
  //   let sellPrice = web3.toWei(0.09)
  //   let result = await instance.setPrices(sellPrice, buyPrice, {from: owner})
  //   let updatedBuyPrice = await instance.getBuyPrice()
  //   let updateSellPrice = await instance.getSellPrice()
  //   assert.equal(buyPrice, updatedBuyPrice, 'Buy price not properly set');
  //   assert.equal(sellPrice, updateSellPrice, 'Sell price not properly set' );
  // })

  // it("should fail while setting the price", async () => {
  //   let buyPrice = web3.toWei(0.2)
  //   let sellPrice = web3.toWei(0.19)
  //   let oldBuyPrice = await instance.getBuyPrice()
  //   let oldSellPrice = await instance.getSellPrice()
  //   try{ 
  //     let result = await instance.setPrices(sellPrice, buyPrice, {from: account});
  //     assert (false, 'Should have thown exception while setting price')
  //   } catch( error) {
  //     console.log('Error:', error)
  //   }
  //   let updatedBuyPrice = await instance.getBuyPrice()
  //   let updateSellPrice = await instance.getSellPrice()
  //   assert.equal(Number(oldBuyPrice), updatedBuyPrice,'Buy price not properly set');
  //   assert.equal(Number(oldSellPrice), updateSellPrice, 'Sell price not properly set');
  // })

  // it("should buy token correctly", async () => {
  //   // Set the prices
  //   let buyPrice = web3.toWei(0.1)
  //   let sellPrice = web3.toWei(0.09)
  //   await instance.setPrices(sellPrice, buyPrice, {from: owner})

  //   // Buy the token
  //   await instance.buy({from: account, value: web3.toWei(1)})

  //   let newBalance = await instance.balanceOf.call(account);
  //   const supplyBalance = await instance.getTokenBalance();
  //   const ethBalance = await instance.getBalance()
  //   assert.equal(newBalance, 10, "Amount wasn't correctly sent to the receiver");
  //   assert.equal(supplyBalance, 1800000000*10**2 - 10, "Amount wasn't correctly deducted from the reciever");
  //   assert.equal(ethBalance, web3.toWei(1), "Ether balance not proper in the account")
  // });

  // it("should fail for selling the token", async () => {
  //   // Try to sell the token
  //   await instance.sell(5, {from: account}).then( () => {
  //     assert (false, 'Should have thown exception while selling')
  //   }).catch( error => {
  //     console.log('Error:', error)
  //   });

  //   let newBalance = await instance.balanceOf.call(account);
  //   const supplyBalance = await instance.getTokenBalance();
  //   const ethBalance = await instance.getBalance()
  //   assert.equal(newBalance, 10, "Token wasn't correctly reset after failing");
  //   assert.equal(supplyBalance, 1800000000*10**2 - 10, "Amount wasn't correctly reset");
  //   assert.equal(ethBalance, web3.toWei(1), "Ether balance not properly reset")
  // });

  it("should withdraw ether correctly", async () => {
    // Check Initial balance
    const ownerOldETHBalance = await proxiedWeb3.eth.getBalance(owner);
    const initialBalance = Number(ownerOldETHBalance)
    const gasPrice = web3.toWei(100,'gwei');
    console.log('Withdrawing', ownerOldETHBalance)
    // Withdraw ether
    const withdrawAmount = web3.toWei(0.004)
    let txnReceipt = await instance.withdraw(withdrawAmount, {from: owner, gasPrice: gasPrice})
    // Calculate gas cost
    const gasUsed = txnReceipt.receipt.gasUsed
    const totgasCost = gasUsed * gasPrice;
    console.log('Withdrawing3')
    // Check Final Balance in the owner and contract account
    const ethBalance = await instance.getBalance()   // contract account balance
    const ownerETHBalance = await proxiedWeb3.eth.getBalance(owner); 
    const finalBalance = Number(ownerETHBalance)

    console.log('EtherBalanceFinal: ',finalBalance,', Old:', initialBalance, ', A:', Number(withdrawAmount))
    assert.equal(ethBalance, web3.toWei(0.6), "Ether balance not proper in the contract account")
    assert.equal(finalBalance, initialBalance + Number(withdrawAmount) - totgasCost, "Ether balance not proper in the owner account")
  });

});
