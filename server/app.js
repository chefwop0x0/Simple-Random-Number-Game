const Koa = require('koa');
const ethers = require('ethers');
require('./config.js');
const app = new Koa();

function getContract() {
  const provider = new ethers.providers.JsonRpcProvider(config_data.providers["mumbai"].endpoint);
  const networkId = config_data.providers["mumbai"].networkId;
  const contract = new ethers.Contract(
    config_data.address,
    config_data.abi,
    provider
  );
  return contract; 
}

const contract = getContract();

app.listen(4000, () => {
  console.log('SimpleRandomNumberGame Server running on port 4000!');

})



async function listenToEvents() {
  // CATCH EVENTS
  console.log("Ready to catch events!");

  contract.on('RandomNumberEvent', async (number, game) => {
    console.log(`RandomNumberEvent logged! - Game: ${game}, Winning Number: ${number}`);
  });

  contract.on('RandomNumberRequestEvent', async (game) => {
    console.log(`RandomNumberRequestEvent logged! - Randomness Requested for Game ${game}`);
  });

  contract.on('PlayEvent', async (player, number, game) => {
    console.log(`PlayEvent logged! - Player ${player} has played Number ${number} for Game ${game}`);
  });

  contract.on('CheckEvent', async (player, game, haswon) => {
    console.log(`CheckEvent logged! - Player ${player} has checked results for Game ${game} - Did she won?: ${haswon}`);
  });

  contract.on('NewGame', async (game) => {
    console.log(`NewGame logged! - New Game: ${game}`);
  });

}

listenToEvents();
