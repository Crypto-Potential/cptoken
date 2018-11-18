pragma solidity ^0.4.4;

contract WithdrawalContract {
  address public richest;
  uint public mostSent;

  mapping (address => uint) pendingWithdrawals;

  constructor() public payable {
    richest = msg.sender;
    mostSent = msg.value;
  }

  function becomeRichest() public payable returns (bool) {
    if (msg.value > mostSent) {
      pendingWithdrawals[richest] += msg.value;
      richest = msg.sender;
      mostSent = msg.value;
      return true;
    } else {
      return false;
    }
  }

  function withdraw() public {
    uint amount = pendingWithdrawals[msg.sender];
    // Remember to zero the pending refund before
    // sending to prevent re-entrancy attacks
    pendingWithdrawals[msg.sender] = 0;
    msg.sender.transfer(amount);
  }
}