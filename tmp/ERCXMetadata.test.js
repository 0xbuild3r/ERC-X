
const {
  BN,
  constants,
  balance,
  expectEvent,
  expectRevert
} = require("@openzeppelin/test-helpers");
const bnChai = require("bn-chai");

require("chai")
  .use(require("chai-as-promised"))
  .use(bnChai(BN))
  .should();

const Item = artifacts.require("./contracts/ERCX/Contract/ERCX.sol");

contract("Item", accounts => {
  let item;
  const [alice, bob, carlos] = accounts;

  beforeEach(async () => {
    item = await Item.new();
  });

  it("Should ERCX be deployed", async () => {
    item.address.should.not.be.null;

    const name = await card.name.call();
    name.should.be.equal("Card");

    const symbol = await card.symbol.call();
    symbol.should.be.equal("CRD");
  });
  
it("Should ZBGCard be deployed", async () => {
  card.address.should.not.be.null;

  const name = await card.name.call();
  name.should.be.equal("Card");

  const symbol = await card.symbol.call();
  symbol.should.be.equal("CRD");
});

it("Should get the correct supply when minting both NFTs and FTs", async () => {
  // Supply is the total amount of UNIQUE cards.
  for (let i = 0; i < 10; i += 2) {
    await card.mint(i, accounts[0], 2);
    await card.mint(i + 1, accounts[0]);
  }
  const supply = await card.totalSupply.call();
  assert.equal(supply, 10);
});

it("Should return correct token uri for multiple NFT", async () => {
  for (let i = 0; i < 100; i++) {
    await card.mint(i, accounts[0]);
    const cardUri = await card.tokenURI.call(i);
    assert.equal(cardUri, `${baseTokenURI}${i}.json`);
  }
});



