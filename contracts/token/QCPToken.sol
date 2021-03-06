pragma solidity ^0.4.4;

import "../library/SafeMath.sol";
import "./basic/Ownable.sol";
import "./basic/StandardToken.sol";
import "./basic/Transferable.sol";
import "./basic/Vestable.sol";

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
  address tokenSupplier;

  // This is a constructor function 
  // which means the following function name has to match the contract name declared above
  constructor() public {
    decimals = 2;                                                 // Amount of decimals for display purposes (CHANGE THIS)
    // If you want your initial tokens to be X and your decimal is 5, set this value to X * 100000. (CHANGE BELOW) 
    totalSupply = 1800000000 * 10 ** uint256(decimals);            // Update total supply (CHANGE THIS)
    tokenSupplier = owner;
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

  // function grantVestedTokens(address _to, uint256 _value, uint64 _start, uint64 _cliff, uint64 _vesting) public {
  //   super.grantVestedTokens(_to, _value, _start, _cliff, _vesting);
  //   require(transfer(_to, _value),"Transfer unsucessful");
  //   emit NewTokenGrant(msg.sender, _to, _value, _cliff, _vesting, _start);
  // }

  function transfer(address _to, uint _value) public canTransfer(msg.sender) canTransferAmount(msg.sender, msg.sender, _value)
    returns (bool success) {
    // Call StandardToken.transfer()
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) public canTransfer(_from) canTransferAmount(_from, msg.sender, _value)
  returns (bool success) {
    // Call StandardToken.transferForm()
    return super.transferFrom(_from, _to, _value);
  }

  function withdraw(uint amount) public onlyOwner returns(bool) {
    require(amount < address(this).balance, "INSUFFICIENT_FUNDS");
    owner.transfer(amount);
    return true;
  }

  function getBalance() public view returns(uint) {
    return address(this).balance;
  }

  function getTokenBalance() public view returns(uint) {
    return balanceOf(tokenSupplier);
  }

  // function spendableBalanceOf(address _holder) public view returns (uint) {
  //   return transferableTokens(_holder, uint64(now));
  // }

  // // @dev How many tokens can a holder transfer at a point in time
  // function transferableTokens(address holder, uint64 time) public view returns (uint256) {
  //   uint256 grantIndex = tokenGrantsCount(holder);

  //   if (grantIndex == 0) return balanceOf(holder); // shortcut for holder without grants

  //   // Iterate through all the grants the holder has, and add all non-vested tokens
  //   uint256 nonVested = 0;
  //   for (uint256 i = 0; i < grantIndex; i++) {
  //     nonVested = nonVested.add(nonVestedTokens(grants[holder][i], time));
  //   }

  //   // Balance - totalNonVested is the amount of tokens a holder can transfer at any given time
  //   return balanceOf(holder).sub(nonVested);
  // }

}