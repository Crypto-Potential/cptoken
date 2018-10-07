const QCPToken = artifacts.require('./QCPToken.sol');
const Web3 = require('web3')

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
    assert.equal(balance.valueOf(), 1800000000*10**2);
  })

  it("should call a function sets the price", async () => {
    let buyPrice = web3.toWei(0.1)
    let sellPrice = web3.toWei(0.09)
    let result = await instance.setPrices(sellPrice, buyPrice, {from: owner})
    let updatedBuyPrice = await instance.getBuyPrice()
    let updateSellPrice = await instance.getSellPrice()
    assert.equal(buyPrice, updatedBuyPrice);
    assert.equal(sellPrice, updateSellPrice);
  })

  it("should buy token correctly", async () => {
    let initialBalance = await instance.balanceOf.call(account);
    let buyPrice = web3.toWei(0.1)
    let sellPrice = web3.toWei(0.09)
    let result = await instance.setPrices(sellPrice, buyPrice, {from: owner})
    console.log('Initial Balance in account:', initialBalance)
    await instance.buy({from: account, value: web3.toWei(1)})
    let newBalance = await instance.balanceOf.call(account);
    console.log('Token Bought:', newBalance)
    const supplyBalance = await instance.getTokenBalance();
    console.log('supplyBalance:', supplyBalance)
    assert.equal(newBalance, 10, "Amount wasn't correctly sent to the receiver");
    // assert.equal(account_two_ending_balance, account_two_starting_balance + amount, "Amount wasn't correctly sent to the receiver");
  });

});
