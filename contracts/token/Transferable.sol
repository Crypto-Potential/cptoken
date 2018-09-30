pragma solidity ^0.4.4;

import "./Ownable.sol";
/**
 * Define interface for releasing the token transfer after a successful crowdsale.
 */
contract Transferable is Ownable {

  /* The finalizer contract that allows unlift the transfer limits on this token */
  address public releaseAgent;

  /** A crowdsale contract can release us to the wild if ICO success. If false we are are in transfer lock up period.*/
  bool public released = false;

  /** Map of agents that are allowed to transfer tokens regardless of the lock down period. These are crowdsale contracts and possible the team multisig itself. */
  mapping (address => bool) public transferAgents;

  constructor() public{
    releaseAgent = msg.sender;
  }

  /**
   * Limit token transfer until the crowdsale is over.
   */
  modifier canTransfer(address _sender) {
    require(released || _sender == owner || transferAgents[_sender], "CANNOT_TRANSFER_TOKEN");
    _;
  }

  /**
   * Set the contract that can call release and make the token transferable.
   */
  function setReleaseAgent(address addr) public onlyOwner inReleaseState(false) {
    // We don't do interface check here as we might want to a normal wallet address to act as a release agent
    releaseAgent = addr;
  }

  /**
   * Owner can allow a particular address (a crowdsale contract) to transfer tokens despite the lock up period.
   */
  function setTransferAgent(address addr, bool state) public onlyOwner inReleaseState(false) {
    transferAgents[addr] = state;
  }

  /**
   * One way function to release the tokens to the wild.
   *
   * Can be called only from the release agent that is the final ICO contract. It is only called if the crowdsale has been success (first milestone reached).
   */
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

  /** The function can be called only before or after the tokens have been releasesd */
  modifier inReleaseState(bool releaseState) {
    require(releaseState == released, "RELEASE_STATE_MISMATCHED");
    _;
  }

  /** The function can be called only by a whitelisted release agent. */
  modifier onlyReleaseAgent() {
    require (msg.sender == releaseAgent,"RELEASEAGENT_ONLY");
    _;
  }

}