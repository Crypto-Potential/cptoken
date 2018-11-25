pragma solidity ^0.4.4;

import "./basic/StandardToken.sol";
import "./basic/Ownable.sol";

contract AdvisorQCP is StandardToken, Ownable {
  
  mapping (address => uint) public canCreateGrants;

  function canTransferToken(address _sender, uint _value) public view returns (bool success){
    return canCreateGrants[_sender] >= _value;
  }

  function setTransferAmount(address _address, uint _value) public onlyOwner{
    canCreateGrants[_address] = _value;
  }

}