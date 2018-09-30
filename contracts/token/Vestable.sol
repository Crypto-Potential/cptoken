pragma solidity ^0.4.4;

import "../installed/SafeMath.sol";

contract Vestable {
  using SafeMath for uint;
    // Keep the struct at 2 sstores (1 slot for value + 64 * 3 (dates) + 20 (address) = 2 slots (2nd slot is 212 bytes, lower than 256))
  struct TokenGrant {
    address granter;
    uint256 value;
    uint64 cliff;
    uint64 vesting;
    uint64 start;
  }

  event NewTokenGrant(address indexed from, address indexed to, uint256 value, uint64 start, uint64 cliff, uint64 vesting);

  mapping (address => TokenGrant[]) public grants;
  mapping (address => bool) canCreateGrants;
  address vestingWhitelister;

  modifier onlyVestingWhitelister {
    require(msg.sender == vestingWhitelister,"ONLY_VESTER");
    _;
  }

  constructor() public{
    vestingWhitelister = msg.sender;
    doSetCanCreateGrants(vestingWhitelister, true);
  }

  function grantVestedTokens(address _to, uint256 _value, uint64 _start, uint64 _cliff, uint64 _vesting) public {
    // Check start, cliff and vesting are properly order to ensure correct functionality of the formula.
    require (_cliff > _start, "Cliff time less than start");
    require (_vesting > _start, "Vesting time less than start");
    require (_vesting > _cliff, "Vesting time less than cliff time");
    require (canCreateGrants[msg.sender], "");
    // To prevent a user being spammed and have his balance locked (out of gas attack when calculating vesting).
    require(tokenGrantsCount(_to) < 20, "Too many grants to the account"); 

    TokenGrant memory grant = TokenGrant(msg.sender, _value, _cliff, _vesting, _start);
    grants[_to].push(grant);
  }

  function setCanCreateGrants(address _addr, bool _allowed) public onlyVestingWhitelister {
    doSetCanCreateGrants(_addr, _allowed);
  }

  function doSetCanCreateGrants(address _addr, bool _allowed) internal {
    canCreateGrants[_addr] = _allowed;
  }

  function changeVestingWhitelister(address _newWhitelister) public onlyVestingWhitelister {
    doSetCanCreateGrants(vestingWhitelister, false);
    vestingWhitelister = _newWhitelister;
    doSetCanCreateGrants(vestingWhitelister, true);
  }

  function tokenGrantsCount(address _holder) public view returns (uint index) {
    return grants[_holder].length;
  }

  function tokenGrant(address _holder, uint _grantId) public view 
  returns (address granter, uint256 value, uint256 vested, uint64 start, uint64 cliff, uint64 vesting) {
    TokenGrant storage grant = grants[_holder][_grantId];

    granter = grant.granter;
    value = grant.value;
    start = grant.start;
    cliff = grant.cliff;
    vesting = grant.vesting;

    vested = vestedTokens(grant, uint64(now));
  }

  function vestedTokens(TokenGrant grant, uint64 time) internal view returns (uint256) {
    return calculateVestedTokens(
      grant.value, uint256(time), uint256(grant.start),uint256(grant.cliff), uint256(grant.vesting)
    );
  }

  function calculateVestedTokens(uint256 tokens, uint256 time, uint256 start, uint256 cliff, uint256 vesting)
  internal view returns (uint256) {
    
    // Shortcuts for before cliff and after vesting cases.
    if (time < cliff) return 0;
    if (time >= vesting) return tokens;

    // Interpolate all vested tokens.
    // As before cliff the shortcut returns 0, we can use just this function to
    // calculate it.

    // uint256 vestedTokensInGrantId = tokens * (time - start) / (vesting - start);
    uint256 vestedTokensInGrantId = (tokens.mul(time.sub(start))).div(vesting.sub(start));
    // uint256 vestedTokensInGrantId = safeDiv(
    //                               safeMul(
    //                                 tokens,
    //                                 safeSub(time, start)
    //                                 ),
    //                               safeSub(vesting, start)
    //                               );

    return vestedTokensInGrantId;
  }

  function nonVestedTokens(TokenGrant grant, uint64 time) internal view returns (uint256) {
    // Of all the tokens of the grant, how many of them are not vested?
    // grantValue - vestedTokens
    return grant.value.sub((vestedTokens(grant, time)));
  }

  // @dev The date in which all tokens are transferable for the holder
  // Useful for displaying purposes (not used in any logic calculations)
  function lastTokenIsTransferableDate(address holder) public view returns (uint64 date) {
    date = uint64(now);
    uint256 grantIndex = tokenGrantsCount(holder);
    for (uint256 i = 0; i < grantIndex; i++) {
      date = grants[holder][i].vesting >= date ? grants[holder][i].vesting : date;
      // date = max64(grants[holder][i].vesting, date);
    }
    return date;
  }

}