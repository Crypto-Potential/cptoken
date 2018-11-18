pragma solidity ^0.4.4;

import "./basic/Ownable.sol";
import "./QCPToken.sol";

contract TradingQCP is Ownable{

  uint256 public sellPrice;           // price in Wei
  uint256 public buyPrice;            // price in Wei
  QCPToken public token;

  constructor(QCPToken _token) public{
    require(_token != address(0), "Token address has to be proper");
    token = _token;
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
    amount = msg.value / buyPrice; // calculates the amount
    token.transfer(msg.sender, amount);  // makes the transfers
    token.transfer(msg.value);  // sends the ether
    return amount;
  }

  /**
  *  @notice Sell `amount` tokens to contract
  *  @param amount amount of tokens to be sold
  */
  function sell(uint256 amount) public returns(uint revenue) {
    revenue = amount * sellPrice;
    require(address(token).balance >= revenue, "INSUFFICIENT_FUNDS"); // checks if the contract has enough ether to buy
    token.transferFrom(msg.sender, this, amount);           // makes the transfers
    msg.sender.transfer(amount * sellPrice);     // sends ether to the seller. It's important to do this last to avoid recursion attacks
  }

  modifier canTransfer(address _sender, uint _value) {
    require(_sender == owner, "CANNOT_TRANSFER_TOKEN");
    _;
  }

  function getBalance() public view returns(uint) {
    return address(this).balance;
  }

  function withdraw(uint256 amount) public onlyOwner returns(bool) {
    owner.transfer(amount);
    return true;
  }

}