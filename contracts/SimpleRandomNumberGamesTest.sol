// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// import chainlink
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
// import openzeppelin
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleRandomNumberGame is VRFConsumerBaseV2, ReentrancyGuard, Ownable {

  event RandomNumberEvent (uint256 number, uint256 game);
  event RandomNumberRequestEvent (uint256 game);
  event PlayEvent (address player, uint256 number, uint256 game);
  event CollectEvent (address player, uint256 game, uint256 amount);
  event NewGame (uint256 game);

  // ChainLink Integration State
  VRFCoordinatorV2Interface COORDINATOR;
  uint64 s_subscriptionId;
  address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
  bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
  uint32 callbackGasLimit = 100000;
  uint16 requestConfirmations = 3;
  uint32 numWords =  1;
  uint256[] public s_randomWords;
  uint256 public s_requestId;

  // Games State
  uint256 public s_min_number;
  uint256 public s_max_number;
  uint256 public s_game_current;
  uint256 public s_game_last;
  uint256 public s_game_duration = 50;
  uint256 public s_game_price;
  bool public s_is_on_draw = false;
  // store for each games an array of players of each number
  mapping(uint => mapping(uint => address[])) public s_games;
  // same as above from the player's perspective
  mapping(address => mapping(uint => mapping(uint => uint))) public s_player_game_numbers;
  // store each game results 0 = winning number, 1 = number of winners, 2 = number of losers
  mapping(uint => uint[]) public s_game_results;
  // store each game jackpot
  mapping(uint => uint) public s_game_prize;
  // each game number of players counter, player can play more numbers for the game but it is always counted as one
  mapping(uint => uint) public s_game_players;
  // each game number of players counter
  mapping(uint => uint) public s_game_tickets;
  // 
  mapping(address => mapping(uint => uint)) public s_player_game_played;
  mapping(address => mapping(uint => uint)) public s_player_game_collected;
  mapping(address => uint[]) public s_player_game_played_array;
  mapping(address => uint[]) public s_player_game_collected_array;

  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_subscriptionId = subscriptionId;
    // set first game
    s_game_current = block.number+s_game_duration;
    s_game_last = 0;
    // set game price
    s_game_price = 0.5 * 10 ** 18;
    s_min_number = 1;
    s_max_number = 10;
  }

  function play(uint _number) external payable {
    require(s_player_game_numbers[msg.sender][s_game_current][_number]==0, "You already played this number for this game!");
    require(_number >= s_min_number && _number <= s_max_number, "Invalid Number");
    require(s_is_on_draw == false, "Draw ongoing!");
    require(msg.value == s_game_price, "Price is not corret!");
    s_player_game_numbers[msg.sender][s_game_current][_number] = 1;
    s_game_prize[s_game_current] += msg.value;
    s_game_tickets[s_game_current] += 1;
    if(s_player_game_played[msg.sender][s_game_current]==0) {
      s_game_players[s_game_current] += 1;
      s_player_game_played[msg.sender][s_game_current] = 1;
      s_player_game_played_array[msg.sender].push(s_game_current);
    }
    s_games[s_game_current][_number].push(msg.sender);
    emit PlayEvent(msg.sender, _number, s_game_current);
  }

  function collect(uint _game) external nonReentrant {
    // check if the game result has been set
    require(s_game_results[_game].length==3, "Game result not set yet!");
    // check player has played the game
    require(s_player_game_played[msg.sender][_game]==1,"You did not play this game!");
    // check player hasn't collected yet
    require(s_player_game_collected[msg.sender][_game]==0,"You already collected for this game!");
    // check if player has played the winning number for the game and calc amount to transfer
    uint amount = (s_player_game_numbers[msg.sender][_game][s_game_results[_game][0]] == 1) ? s_game_prize[_game]/s_game_results[_game][1] : 0;
    //update player collections state
    s_player_game_collected[msg.sender][_game]==1;
    s_player_game_collected_array[msg.sender].push(_game);
    if(amount>0) {
      //transfer ETH to winner
      payable(msg.sender).transfer(amount);
    }
    emit CollectEvent(msg.sender, _game, amount);
  }

  function requestRandomWords() external onlyOwner {
    require(s_is_on_draw == false, "Draw ongoing!");
    require(block.number >= s_game_current, "Current Game has not expired yet!");
    // if there is a jackpot, let's run the draw otherwise set blank results
    if(s_game_prize[s_game_current]>0) {
        s_requestId = COORDINATOR.requestRandomWords(
        keyHash,
        s_subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
        );
        emit RandomNumberRequestEvent(s_game_last);
        s_is_on_draw = true;
    } else {
        s_game_results[s_game_current].push(0);
        s_game_results[s_game_current].push(0);
        s_game_results[s_game_current].push(0);
    }
    // rotate games
    s_game_last = s_game_current;
    s_game_current = block.number+s_game_duration;
    emit NewGame(s_game_current);
  }
  // only for testing purpose
  function triggerFulFill() external {
    uint256[] memory arr;
    arr[0] = 3234234823402384923804820342342342342342342342344234234234234234239292929233;
    fulfillRandomWords(345, arr);
  }

  function fulfillRandomWords(uint256, /* requestId,*/ uint256[] memory randomWords) internal override {
    s_randomWords = randomWords;
    for(uint i=0; i<s_randomWords.length; ++i) {
      // calc winning number
      uint winningNumber = (s_randomWords[i] % (s_max_number-1)) + 1;
      // store game winning number
      s_game_results[s_game_last].push(winningNumber);
      // store game winners count
      s_game_results[s_game_last].push(s_games[s_game_last][winningNumber].length);
      // store game losers count
      s_game_results[s_game_last].push(s_game_players[s_game_last]-s_game_results[s_game_last][1]);
      emit RandomNumberEvent(winningNumber, s_game_last);
    }
    s_is_on_draw = false;
  }

  function getContractBalance() external view returns(uint) {
    return address(this).balance;
  }

  // get all the games player has played
  function getGamesPlayed(address _player) external view returns(uint[] memory) {
    return s_player_game_played_array[_player];
  }

  // get all the games player has collected
  function getGamesCollected(address _player) external view returns(uint[] memory) {
    return s_player_game_collected_array[_player];
  }

}
