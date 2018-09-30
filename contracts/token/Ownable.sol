pragma solidity ^0.4.4;

contract owned {
  address public owner;
  address private ownerCandidate;

  constructor() public{
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner, "OWNER_ONLY");
    _;
  }

  modifier onlyOwnerCandidate() {
    require(msg.sender == ownerCandidate, "OWNERCANDIDATE_ONLY");
    _;
  }
  /**
   *  Add the candidate for transferring ownership so that it takes care that owner is a proper address
   */
  function transferOwnership(address candidate) external onlyOwner {
    ownerCandidate = candidate;
  }

  function acceptOwnership() external onlyOwnerCandidate {
    owner = ownerCandidate;
  }
}