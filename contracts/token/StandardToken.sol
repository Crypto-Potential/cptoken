pragma solidity ^0.4.4;

import "./Ownable.sol";

interface tokenRecipient {
   function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; 
}

contract Token {

  // @return total amount of tokens
  function totalSupply() public view returns (uint256 supply) {}

  // @param _owner The address from which the balance will be retrieved
  // @return The balance
  function balanceOf(address _owner) public view  returns (uint256 balance) {}

  // @notice send `_value` token to `_to` from `msg.sender`
  // @param _to The address of the recipient
  // @param _value The amount of token to be transferred
  // @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) public returns (bool success) {}

  // @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  // @param _from The address of the sender
  // @param _to The address of the recipient
  // @param _value The amount of token to be transferred
  // @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}

  // @notice `msg.sender` approves `_addr` to spend `_value` tokens
  // @param _spender The address of the account able to transfer the tokens
  // @param _value The amount of wei to be approved for transfer
  // @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) public returns (bool success) {}

  // @param _owner The address of the account owning tokens
  // @param _spender The address of the account able to transfer the tokens
  // @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {

  /**
    * Internal transfer, only can be called by this contract
    */
  function _transfer(address _from, address _to, uint _value) internal {
    // Prevent transfer to 0x0 address. Use burn() instead
    require(_to != 0x0, "BURNING_DISALLOWED");
    // Check if the sender has enough
    require(balances[_from] >= _value,"INSUFFICIENT_TOKEN");
    // Check for overflows
    require(balances[_to] + _value >= balances[_to],"OVERFLOW_ERROR");
    // Save this for an assertion in the future
    uint previousBalances = balances[_from] + balances[_to];
    // Subtract from the sender
    balances[_from] -= _value;
    // Add the same to the recipient
    balances[_to] += _value;
    emit Transfer(_from, _to, _value);
    // Asserts are used to use static analysis to find bugs in your code. They should never fail
    assert(balances[_from] + balances[_to] == previousBalances);
  }

  /**
    * Transfer tokens
    * Send `_value` tokens to `_to` from your account
    * @param _to The address of the recipient
    * @param _value the amount to send
    */
  function transfer(address _to, uint256 _value) public returns (bool success) {
    require(_value > 0,"NEGATIVE_TRANSFER");
    _transfer(msg.sender, _to, _value);
    return true;
  }

  /**
    * Transfer tokens from other address
    * Send `_value` tokens to `_to` on behalf of `_from`
    * @param _from The address of the sender
    * @param _to The address of the recipient
    * @param _value the amount to send
    */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value > 0,"NEGATIVE_TRANSFER");
    require(_value <= allowed[_from][msg.sender],"NOT_ALLOWED");     // Check allowance
    allowed[_from][msg.sender] -= _value;
    _transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  /**
    * Set allowance for other address
    * Allows `_spender` to spend no more than `_value` tokens on your behalf
    * @param _spender The address authorized to spend
    * @param _value the max amount they can spend
    * Updates to handle the token approval issue
    * https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit
    */
  function approve(address _spender, uint256 _value) public returns (bool success) {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0), "ZERO_RESET");
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
    * Set allowance for other address and notify
    * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
    * @param _spender The address authorized to spend
    * @param _value the max amount they can spend
    * @param _extraData some extra information to send to the approved contract
    */
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
    tokenRecipient spender = tokenRecipient(_spender);
    if (approve(_spender, _value)) {
      spender.receiveApproval(msg.sender, _value, this, _extraData);
      return true;
    }
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  uint256 public totalSupply;
}