pragma solidity ^0.4.4;

import "./Ownable.sol";
import "./StandardToken.sol";

contract Vestable is Ownable{
  mapping (address => bool) vestableAddress;

  mapping (address => bool) public vestableAgents;

  modifier canTransferAmount(address _sender, address _agent, uint _value) {
    require(!vestableAddress[_sender] || vestableAgents[_agent], "CANNOT TRANSFER AMOUNT");
    _;
  }

  function setVestableAddress(address _addr, bool state) public onlyOwner {
    vestableAddress[_addr] = state;
  }

  function setVestableAgent(address _addr, bool state) public onlyOwner {
    vestableAgents[_addr] = state;
  }

}