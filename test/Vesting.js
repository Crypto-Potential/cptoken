// Slightly modified Zeppelin tests for ERC20 VestedToken.

const assertJump = require('./helpers/assertJump');
var AragonTokenSaleTokenMock = artifacts.require("./helpers/AragonTokenSaleTokenMock");
var MiniMeIrrevocableVestedToken = artifacts.require("MiniMeIrrevocableVestedToken");
const timer = require('./helpers/timer');

contract('QCPToken', function(accounts) {
  let token = null
  let now = 0

  const tokenAmount = 50

  const granter = accounts[0]
  const receiver = accounts[1]

  beforeEach(async () => {
    const sale = await AragonTokenSaleTokenMock.new(granter, 100);
    token = MiniMeIrrevocableVestedToken.at(await sale.token());
    now = web3.eth.getBlock(web3.eth.blockNumber).timestamp;
  })

  it('granter can grant tokens without vesting', async () => {
    await token.transfer(receiver, tokenAmount, { from: granter })

    assert.equal(await token.balanceOf(receiver), tokenAmount);
    assert.equal(await token.transferableTokens(receiver, now), tokenAmount);
  })

  it('cannot create token grants after losing whitelisting ability', async () => {
    await token.changeVestingWhitelister(accounts[2]);
    try {
      await token.grantVestedTokens(receiver, tokenAmount, now, now + 10000, now + 20000, { from: granter })
    } catch(error) {
      return assertJump(error);
    }
  })

  it('can create token grants after being whitelisted', async () => {
    await token.changeVestingWhitelister(accounts[2]);
    await token.setCanCreateGrants(accounts[0], true, { from: accounts[2] });
    await token.grantVestedTokens(receiver, tokenAmount, now, now + 10000, now + 20000, { from: granter });
    assert.equal(await token.balanceOf(receiver), tokenAmount);
  })

  it('cannot whitelist ppl after losing vesting whitelisting ability', async () => {
    await token.changeVestingWhitelister(accounts[2]);
    try {
      await token.setCanCreateGrants(accounts[2], true, { from: accounts[0] });
    } catch(error) {
      return assertJump(error);
    }
  })

  describe('getting a token grant', async () => {
    const cliff = 10000
    const vesting = 20000 // seconds

    beforeEach(async () => {
      await token.grantVestedTokens(receiver, tokenAmount, now, now + cliff, now + vesting, { from: granter })
    })

    it('tokens are received', async () => {
      assert.equal(await token.balanceOf(receiver), tokenAmount);
    })

    it('has 0 transferable tokens before cliff', async () => {
      assert.equal(await token.transferableTokens(receiver, now), 0);
    })

    it('all tokens are transferable after vesting', async () => {
      assert.equal(await token.transferableTokens(receiver, now + vesting), tokenAmount);
    })

    it('throws when trying to transfer non vested tokens', async () => {
      try {
        await token.transfer(accounts[7], 1, { from: receiver })
      } catch(error) {
        return assertJump(error);
      }
      assert.fail('should have thrown before');
    })

    it('throws when trying to transfer from non vested tokens', async () => {
      try {
        await token.approve(accounts[7], 1, { from: receiver })
        await token.transferFrom(receiver, accounts[7], tokenAmount, { from: accounts[7] })
      } catch(error) {
        return assertJump(error);
      }
      assert.fail('should have thrown before');
    })

    it('cannot be revoked', async () => {
      try {
        await token.revokeTokenGrant(receiver, 0, { from: granter });
      } catch(error) {
        return assertJump(error);
      }
    })

    it('can transfer all tokens after vesting ends', async () => {
      await timer(vesting);
      await token.transfer(accounts[7], tokenAmount, { from: receiver })
      assert.equal(await token.balanceOf(accounts[7]), tokenAmount);
    })

    it('can approve and transferFrom all tokens after vesting ends', async () => {
      await timer(vesting);
      await token.approve(accounts[7], tokenAmount, { from: receiver })
      await token.transferFrom(receiver, accounts[7], tokenAmount, { from: accounts[7] })
      assert.equal(await token.balanceOf(accounts[7]), tokenAmount);
    })

    it('can handle composed vesting schedules', async () => {
      await timer(cliff);
      await token.transfer(accounts[7], 12, { from: receiver })
      assert.equal(await token.balanceOf(accounts[7]), 12);

      let newNow = web3.eth.getBlock(web3.eth.blockNumber).timestamp

      await token.grantVestedTokens(receiver, tokenAmount, newNow, newNow + cliff, newNow + vesting, { from: granter })
      await token.transfer(accounts[7], 13, { from: receiver })
      assert.equal(await token.balanceOf(accounts[7]), tokenAmount / 2);

      assert.equal(await token.balanceOf(receiver), 3 * tokenAmount / 2)
      assert.equal(await token.transferableTokens(receiver, newNow), 0)
      await timer(vesting);
      await token.transfer(accounts[7], 3 * tokenAmount / 2, { from: receiver })
      assert.equal(await token.balanceOf(accounts[7]), tokenAmount * 2)
    })
  })
});
