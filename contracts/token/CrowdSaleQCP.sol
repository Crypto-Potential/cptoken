pragma solidity ^0.4.4;

import "../library/SafeMath.sol";
import "./basic/StandardToken.sol";

contract CrowdSaleQCP {
  using SafeMath for uint256;

  StandardToken public token;
  address public wallet;
  uint256 public rate;
  uint256 public weiRaised;

  constructor(uint256 _rate, address _wallet, StandardToken _token) public{
    require(_rate > 0, "Rate has to be Non-Zero");
    require(_wallet != address(0), "Wallet Address");
    require(_token != address(0), "Token address has to be proper");
    rate = _rate;
    wallet = _wallet;
    token = _token;
  }
  
  function buyTokens(address _beneficiary) public payable {
    require(_beneficiary != address(0));
    require(msg.value != 0);

    uint256 tokens = msg.value.mul(rate);
    weiRaised = weiRaised.add(msg.value);

    token.transfer(_beneficiary, tokens);
    wallet.transfer(msg.value);
  }

}


