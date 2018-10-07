pragma solidity ^0.4.4;

import "./Ownable.sol";
import "./StandardToken.sol";
import "./Transferable.sol";
import "./Vestable.sol";
import "../library/SafeMath.sol";

contract QCPToken is StandardToken, Ownable, Transferable, Vestable {
  using SafeMath for uint;
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

  uint256 public sellPrice;           // price in Wei
  uint256 public buyPrice;            // price in Wei
  event Log(string _myString);
  address tokenSupplier;
  // This is a constructor function 
  // which means the following function name has to match the contract name declared above
  constructor() public {
    decimals = 2;                                                 // Amount of decimals for display purposes (CHANGE THIS)
    // If you want your initial tokens to be X and your decimal is 5, set this value to X * 100000. (CHANGE BELOW) 
    totalSupply = 1800000000 * 10 ** uint256(decimals);            // Update total supply (CHANGE THIS)
    tokenSupplier = this;
    balances[tokenSupplier] = totalSupply;                            // Give the creator all initial tokens.                 
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

  function getBuyPrice() public view returns(uint) {
    return buyPrice;
  }

  function getSellPrice() public view returns(uint){
    return sellPrice;
  }
  /** 
  *  @notice Buy tokens from contract by sending ether
  */
  function buy() public payable  returns(uint amount) {
    amount = msg.value / buyPrice;               // calculates the amount
    _transfer(tokenSupplier, msg.sender, amount);         // makes the transfers
    return amount;
  }

  function grantVestedTokens(address _to, uint256 _value, uint64 _start, uint64 _cliff, uint64 _vesting) public {
    super.grantVestedTokens(_to, _value, _start, _cliff, _vesting);
    require(transfer(_to, _value),"Transfer unsucessful");
    emit NewTokenGrant(msg.sender, _to, _value, _cliff, _vesting, _start);
  }

  /**
  *  @notice Sell `amount` tokens to contract
  *  @param amount amount of tokens to be sold
  */
  function sell(uint256 amount) public returns(uint revenue){
    revenue = amount * sellPrice;
    require(tokenSupplier.balance >= revenue, "INSUFFICIENT_FUNDS"); // checks if the contract has enough ether to buy
    _transfer(msg.sender, tokenSupplier, amount);        // makes the transfers
    msg.sender.transfer(amount * sellPrice);    // sends ether to the seller. It's important to do this last to avoid recursion attacks
  }

  function _transfer(address _from, address _to, uint _value) internal canTransferAmount(_from, _value){
    // Call StandardToken._transfer()
    super._transfer(_from, _to, _value);
  }

  function transfer(address _to, uint _value) public canTransferAmount(msg.sender, _value)
  returns (bool success) {
    // Call StandardToken.transfer()
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) public canTransferAmount(_from, _value) 
  returns (bool success) {
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

  function getTokenBalance() public view returns(uint) {
    return balanceOf(this);
  }

  modifier canTransferAmount(address _sender, uint _value) {
    require(released || _sender == tokenSupplier || transferAgents[_sender], "CANNOT_TRANSFER_TOKEN");
    require(_sender == tokenSupplier || _value < spendableBalanceOf(_sender), "CANNOT_SPEND");
    _;
  }

  function spendableBalanceOf(address _holder) public view returns (uint) {
    return transferableTokens(_holder, uint64(now));
  }

  // @dev How many tokens can a holder transfer at a point in time
  function transferableTokens(address holder, uint64 time) public view returns (uint256) {
    uint256 grantIndex = tokenGrantsCount(holder);

    if (grantIndex == 0) return balanceOf(holder); // shortcut for holder without grants

    // Iterate through all the grants the holder has, and add all non-vested tokens
    uint256 nonVested = 0;
    for (uint256 i = 0; i < grantIndex; i++) {
      nonVested = nonVested.add(nonVestedTokens(grants[holder][i], time));
    }

    // Balance - totalNonVested is the amount of tokens a holder can transfer at any given time
    return balanceOf(holder).sub(nonVested);
  }

}