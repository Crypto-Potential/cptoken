pragma solidity ^0.4.4;

import "./Ownable.sol";
import "./StandardToken.sol";
import "./Transferable.sol";
import "./Withdrawable.sol";

contract QCPToken is StandardToken, owned, transferable {

  /* Public variables of the token */

  /*
  NOTE:
  The following variables are OPTIONAL vanities. One does not have to include them.
  They allow one to customise the token contract & in no way influences the core functionality.
  Some wallets/interfaces might not even bother to look at this information.
  */
  string public name;                   // Token Name
  uint8 public decimals;                // How many decimals to show. To be standard complicant keep it 18
  string public symbol;                 // An identifier: eg SBX, XPR etc..
  string public version = "H1.0"; 

  uint256 public sellPrice;
  uint256 public buyPrice;
  // This is a constructor function 
  // which means the following function name has to match the contract name declared above
  constructor() public {
    decimals = 18;                                                 // Amount of decimals for display purposes (CHANGE THIS)
    // If you want your initial tokens to be X and your decimal is 5, set this value to X * 100000. (CHANGE BELOW) 
    totalSupply = 1800000000 * 10 ** uint256(decimals);            // Update total supply (CHANGE THIS)
    balances[owner] = totalSupply;                            // Give the creator all initial tokens.                 
    name = "CryptoPotential";                                     // Set the name for display purposes (CHANGE THIS)
    symbol = "QCP";                                               // Set the symbol for display purposes (CHANGE THIS)
  }

  function mintToken(address target, uint256 mintedAmount) public onlyOwner {
    balances[target] += mintedAmount;
    totalSupply += mintedAmount;
    emit Transfer(0, owner, mintedAmount);
    if (owner != target) {
      emit Transfer(owner, target, mintedAmount);
    }
  }

  /**
  *  @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
  *  @param newSellPrice Price the users can sell to the contract
  *  @param newBuyPrice Price users can buy from the contract
  */
  function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
    sellPrice = newSellPrice;
    buyPrice = newBuyPrice;
  }

  /** 
  *  @notice Buy tokens from contract by sending ether
  */
  function buy() public payable  returns(uint amount) {
    amount = msg.value / buyPrice;               // calculates the amount
    _transfer(this, msg.sender, amount);         // makes the transfers
    return amount;
  }

  /**
  *  @notice Sell `amount` tokens to contract
  *  @param amount amount of tokens to be sold
  */
  function sell(uint256 amount) public returns(uint revenue){
    address myAddress = this;
    revenue = amount * sellPrice;
    require(myAddress.balance >= revenue, "INSUFFICIENT_FUNDS"); // checks if the contract has enough ether to buy
    _transfer(msg.sender, this, amount);        // makes the transfers
    msg.sender.transfer(amount * sellPrice);    // sends ether to the seller. It's important to do this last to avoid recursion attacks
  }

  function transfer(address _to, uint _value) public canTransfer(msg.sender) returns (bool success) {
    // Call StandardToken.transfer()
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) public canTransfer(_from) returns (bool success) {
    // Call StandardToken.transferForm()
    return super.transferFrom(_from, _to, _value);
  }

  function withdraw(uint amount) public onlyOwner returns(bool) {
    require(amount < address(this).balance,"INSUFFICIENT_FUNDS");
    owner.transfer(amount);
    return true;
  }

  function getBalance() public view returns(uint) {
    return address(this).balance;
  }

}