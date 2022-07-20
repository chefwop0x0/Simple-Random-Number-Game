const SimpleRandomNumberGame = artifacts.require("SimpleRandomNumberGame");
require("dotenv").config({ path: ".env" });

module.exports = async (deployer, network, accounts) => { 
    await deployer.deploy(SimpleRandomNumberGame, process.env.SUBSCRIPTION_ID);
    SimpleRandomNumberGameInstance = await SimpleRandomNumberGame.deployed();
    console.log(`SimpleRandomNumberGameInstance address: ${SimpleRandomNumberGameInstance.address}`);
};
