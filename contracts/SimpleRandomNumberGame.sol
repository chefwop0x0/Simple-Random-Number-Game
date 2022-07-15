// SPDX-License-Identifier: MIT
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
  address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
  bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
  uint32 callbackGasLimit = 100000;
  uint16 requestConfirmations = 3;
  uint32 numWords =  1;

  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address s_owner;
  uint256 public s_game;
  bool public s_is_on_draw = false;
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
    require(s_is_on_draw == false, "Draw ongoing!");
    s_player_game_number[msg.sender][s_game] = _number;
    emit PlayEvent(msg.sender, _number, s_game);
  }

  function check(uint _game) external view returns(bool) {
    require(s_game_result[_game]!=0, "Game result not set yet!");
    bool result = (s_player_game_number[msg.sender][_game] == s_game_result[_game]) ? true : false;
    //emit CheckEvent(msg.sender, s_game, result);
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
    s_is_on_draw = true;
    emit RandomNumberRequestEvent(s_game);
  }
  
  function fulfillRandomWords(uint256, /* requestId */ uint256[] memory randomWords) internal override {
    s_randomWords = randomWords;
    for(uint i=0; i<s_randomWords.length; ++i) {
      uint randomNumber = (s_randomWords[i] % 9) + 1;
      s_game_result[s_game] = randomNumber;
      emit RandomNumberEvent(randomNumber, s_game);
    }
    s_is_on_draw = false;
    s_game = block.number;
    emit NewGame(s_game);
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }

}
