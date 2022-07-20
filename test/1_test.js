const SimpleRandomNumberGame = artifacts.require("SimpleRandomNumberGame");
const truffleAssert = require('truffle-assertions');
const { time } = require("@openzeppelin/test-helpers");
const { assertion } = require('@openzeppelin/test-helpers/src/expectRevert');
var expect = require('expect.js');

contract("SimpleRandomNumberGame", (accounts) => {

    before(async () =>  {
        SimpleRandomNumberGameInstance = await SimpleRandomNumberGame.deployed();
    });

    it("Test", async () => {
        assert.equal(1, 1, "Wrong!");
    });

});