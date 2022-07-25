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
  uint256 public s_game_price;
  bool public s_is_on_draw = false;
  mapping(uint => mapping(uint => address[])) public s_games;
  mapping(address => mapping(uint => mapping(uint => uint))) public s_player_game_numbers;
  mapping(uint => uint[]) public s_game_results;
  mapping(uint => uint) public s_game_prize;
  mapping(uint => uint) public s_game_players;
  mapping(uint => uint) public s_game_tickets;
  mapping(address => mapping(uint => uint)) public s_player_game_played;
  mapping(address => uint[]) public s_player_game_played_array;

  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
    s_game = block.number;
    s_game_price = 0.5 * 10 ** 18;
  }

  function play(uint _number) external payable {
    require(s_player_game_numbers[msg.sender][s_game][_number]==0, "You already played this number for this game!");
    require(_number > 0 && _number < 11, "Invalid Number");
    require(s_is_on_draw == false, "Draw ongoing!");
    require(msg.value == s_game_price, "Price is not corret!");
    s_player_game_numbers[msg.sender][s_game][_number] = 1;
    s_game_prize[s_game] += msg.value;
    s_game_tickets[s_game] += 1;
    if(s_player_game_played[msg.sender][s_game]==0) {
      s_game_players[s_game] += 1;
      s_player_game_played[msg.sender][s_game] = 1;
      s_player_game_played_array[msg.sender].push(s_game);
    }
    s_games[s_game][_number].push(msg.sender);
    emit PlayEvent(msg.sender, _number, s_game);
  }

  function check(uint _game) external view returns(bool) {
    require(s_game_results[_game].length!=0, "Game result not set yet!");
    bool result = (s_player_game_numbers[msg.sender][s_game][s_game_results[s_game][0]] == 1) ? true : false;
    //emit CheckEvent(msg.sender, s_game, result);
    return result;
  }

  function requestRandomWords() external onlyOwner {
    require(s_is_on_draw == false, "Draw ongoing!");
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
      uint winningNumber = (s_randomWords[i] % 9) + 1;
      // store sb winning number
      s_game_results[s_game].push(winningNumber);
      // store sb winners count
      s_game_results[s_game].push(s_games[s_game][winningNumber].length);
      // store sb losers count
      s_game_results[s_game].push(s_game_players[s_game]-s_game_results[s_game][1]);
      emit RandomNumberEvent(winningNumber, s_game);
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
