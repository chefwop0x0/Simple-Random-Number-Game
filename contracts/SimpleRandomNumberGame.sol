// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
/*
- create subscription
- deploy contract
- send LINK to contract
- launch node script to catch events
- from remix, play 1 number
- check should revert
- request randomness
- show winning number
- check if player has won or not
*/

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract SimpleRandomNumberGame is VRFConsumerBaseV2 {

  event RandomNumberEvent (uint number, uint game);
  event RandomNumberRequestEvent (uint game);
  event PlayEvent (address player, uint number, uint game);
  event CheckEvent (address player, uint game, bool haswon);
  event NewGame (uint game);

  VRFCoordinatorV2Interface COORDINATOR;
  uint64 s_subscriptionId;
  address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
  bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
  uint32 callbackGasLimit = 100000;
  uint16 requestConfirmations = 3;
  uint32 numWords =  1;

  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address s_owner;
  uint256 public s_game;
  mapping(address => mapping(uint => uint)) public s_player_game_number;
  mapping(uint => uint) public s_game_result;

  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
    s_game = block.number;
  }

  function play(uint _number) external {
    require(s_player_game_number[msg.sender][s_game]==0, "You already played this game!");
    require(_number > 0 && _number < 11, "Invalid Number");
    s_player_game_number[msg.sender][s_game] = _number;
    emit PlayEvent(msg.sender, _number, s_game);
  }

  function check(uint _game) external returns(bool) {
    require(s_game_result[_game]!=0, "Game result not set yet!");
    bool result = (s_player_game_number[msg.sender][_game] == s_game_result[_game]) ? true : false;
    emit CheckEvent(msg.sender, s_game, result);
    return result;
  }

  function requestRandomWords() external onlyOwner {
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
    emit RandomNumberRequestEvent(s_game);
  }
  
  function fulfillRandomWords(uint256, /* requestId */ uint256[] memory randomWords) internal override {
    s_randomWords = randomWords;
    for(uint i=0; i<s_randomWords.length; ++i) {
      uint randomNumber = s_randomWords[i] % 10;
      s_game_result[s_game] = randomNumber;
      emit RandomNumberEvent(randomNumber, s_game);
    }
    s_game = block.number;
    emit NewGame(s_game);
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }

}
