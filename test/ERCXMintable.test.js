require("@openzeppelin/test-helpers/configure")({
  provider: web3.currentProvider,
  singletons: { defaultGas: 1000000, abstraction: "truffle" }
});

const {
  BN,
  constants,
  balance,
  expectEvent,
  expectRevert
} = require("@openzeppelin/test-helpers");

const { ZERO_ADDRESS } = constants;
const { expect } = require("chai");
/*
const bnChai = require("bn-chai");

require("chai")
  .use(require("chai-as-promised"))
  .use(bnChai(BN))
  .should();
*/

const Item = artifacts.require("./contracts/ERCX/Contract/ERCXMintable.sol");

contract("Item", accounts => {
  let item;
  const [creator, ...otherAccounts] = accounts;
  const minter = creator;
  const [
    owner,
    newOwner,
    approvedTransfer,
    approvedSuspension,
    operator,
    other
  ] = otherAccounts;

  const name = "TEST";
  const symbol = "TST";
  const MOCK_URI = "https://example.com";

  const data = "0x42";
  const ERCXRECEIVER_MAGIC_VALUE = "0x11111111";
  const ERC721RECEIVER_MAGIC_VALUE = "0x00000000";

  const firstItemId = new BN(100);
  const secondItemId = new BN(200);
  const thirdItemId = new BN(300);
  const nonExistentItemId = new BN(999);

  beforeEach(async () => {
    item = await Item.new(name, symbol, { from: creator });
  });

  it("Should ERCX be deployed", async () => {
    expect(item.address).to.exist;
  });

  describe("like a mintable ERCX", function() {
    beforeEach(async () => {
      await item.mintWithItemURI(owner, firstItemId, MOCK_URI, {
        from: minter
      });
      await item.mintWithItemURI(owner, secondItemId, MOCK_URI, {
        from: minter
      });
    });

    describe("balanceOf in ERCX", function() {
      context(
        "when the given address owns some items in layer2 as ERCX",
        function() {
          it("returns the amount of items owned by the given address", async function() {
            expect(await item.balanceOf(owner, 2)).to.be.bignumber.equal("2");
          });
        }
      );

      context(
        "when the given address does not own any items in layer2 as ERCX",
        function() {
          it("returns 0", async function() {
            expect(await item.balanceOf(other, 2)).to.be.bignumber.equal("0");
          });
        }
      );

      context("when querying the zero address of layer2", function() {
        it("throws", async function() {
          await expectRevert.unspecified(item.balanceOf(ZERO_ADDRESS, 2));
        });
      });
    });

    describe("balanceOf in ERC721", function() {
      context("when the given address owns some items as ERC721", function() {
        it("returns the amount of items owned by the given address", async function() {
          expect(await item.balanceOf(owner)).to.be.bignumber.equal("2");
        });
      });

      context(
        "when the given address does not own any items as ERC721",
        function() {
          it("returns 0", async function() {
            expect(await item.balanceOf(other)).to.be.bignumber.equal("0");
          });
        }
      );

      context("when querying the zero address", function() {
        it("throws", async function() {
          await expectRevert.unspecified(item.balanceOf(ZERO_ADDRESS));
        });
      });
    });

    describe("ownerOf in ERCX", function() {
      context("when the given item ID was tracked by this item", function() {
        const itemId = firstItemId;
        it("returns the owner of the given item ID ERCX in layer2", async function() {
          expect(await item.ownerOf(itemId, 2)).to.be.equal(owner);
        });
      });

      context(
        "when the given item ID was not tracked by this item",
        function() {
          const itemId = nonExistentItemId;
          it("reverts", async function() {
            await expectRevert.unspecified(item.ownerOf(itemId, 2));
          });
        }
      );

      context(
        "when the given item ID was tracked by this item but layer was higher than 3",
        function() {
          const itemId = firstItemId;
          it("returns the owner of the given item ID ERCX in layer4", async function() {
            await expectRevert.unspecified(await item.ownerOf(itemId, 4));
          });
        }
      );
    });

    describe("ownerOf in ERC721", function() {
      context("when the given item ID was tracked by this item", function() {
        const itemId = firstItemId;
        it("returns the owner of the given item ID as ERC721", async function() {
          expect(await item.ownerOf(itemId)).to.be.equal(owner);
        });
      });

      context(
        "when the given item ID was not tracked by this item",
        function() {
          const itemId = nonExistentItemId;
          it("reverts", async function() {
            await expectRevert.unspecified(item.ownerOf(itemId));
          });
        }
      );
    });

    describe("superOf in ERCX", function() {
      context("when the given item ID was tracked by this item", function() {
        const itemId = firstItemId;

        it("returns the owner of the given item ID ERCX in layer3", async function() {
          expect(await item.superOf(itemId, 2)).to.be.equal(owner);
        });
      });

      context(
        "when the given item ID was not tracked by this item",
        function() {
          const itemId = nonExistentItemId;
          it("reverts", async function() {
            await expectRevert.unspecified(item.superOf(itemId, 2));
          });
        }
      );

      context(
        "when the given item ID was tracked by this item but layer was higher than 3",
        function() {
          const itemId = firstItemId;
          it("reverts", async function() {
            await expectRevert.unspecified(item.superOf(itemId, 3));
          });
        }
      );
    });

    describe("transfers in ERC721", function() {
      const itemId = firstItemId;
      let logs = null;

      beforeEach(async function() {
        await item.approve(approvedTransfer, itemId, { from: owner });
        await item.setApprovalForAll(operator, true, { from: owner });
      });

      const transferWasSuccessful721 = function({
        owner,
        itemId,
        approvedTransfer
      }) {
        it("transfers the ownership of the given item ID to the given address", async function() {
          expect(await item.ownerOf(itemId)).to.be.equal(other);
        });

        it("clears the approval for the item ID", async function() {
          expect(await item.getApproved(itemId)).to.be.equal(ZERO_ADDRESS);
        });

        if (approvedTransfer) {
          it("emit only a transfer event", async function() {
            expectEvent.inLogs(logs, "Transfer", {
              from: owner,
              to: other,
              itemId: itemId
            });
          });
        } else {
          it("emits only a transfer event", async function() {
            expectEvent.inLogs(logs, "Transfer", {
              from: owner,
              to: other,
              itemId: itemId
            });
          });
        }

        it("adjusts owners balances", async function() {
          expect(await item.balanceOf(owner)).to.be.bignumber.equal("1");
        });

        it("adjusts owners items by index", async function() {
          if (!item.itemOfOwnerByIndex) return;

          expect(
            await item.itemOfOwnerByIndex(other, 0, 1)
          ).to.be.bignumber.equal(itemId);

          expect(
            await item.itemOfOwnerByIndex(owner, 0, 1)
          ).to.be.bignumber.not.equal(itemId);
        });
      };

      const shouldTransferItemsByUsers721 = function(transferFunction) {
        context("when called by the owner", function() {
          beforeEach(async function() {
            ({ logs } = await transferFunction.call(
              this,
              owner,
              other,
              itemId,
              { from: owner }
            ));
          });
          transferWasSuccessful721({ owner, itemId, approvedTransfer });
        });

        context("when called by the approvedTransfer individual", function() {
          beforeEach(async function() {
            ({ logs } = await transferFunction.call(
              this,
              owner,
              other,
              itemId,
              { from: approvedTransfer }
            ));
          });
          transferWasSuccessful721({ owner, itemId, approvedTransfer });
        });

        context("when called by the operator", function() {
          beforeEach(async function() {
            ({ logs } = await transferFunction.call(
              this,
              owner,
              other,
              itemId,
              { from: operator }
            ));
          });
          transferWasSuccessful721({ owner, itemId, approvedTransfer });
        });

        context(
          "when called by the owner without an approvedTransfer user",
          function() {
            beforeEach(async function() {
              await item.approve(ZERO_ADDRESS, itemId, { from: owner });
              ({ logs } = await transferFunction.call(
                this,
                owner,
                other,
                itemId,
                { from: operator }
              ));
            });
            transferWasSuccessful721({ owner, itemId, approvedTransfer: null });
          }
        );

        context("when sent to the owner", function() {
          beforeEach(async function() {
            ({ logs } = await transferFunction.call(
              this,
              owner,
              owner,
              itemId,
              { from: owner }
            ));
          });

          it("keeps ownership of the item", async function() {
            expect(await item.ownerOf(itemId)).to.be.equal(owner);
          });

          it("clears the approval for the item ID", async function() {
            expect(await item.getApproved(itemId)).to.be.equal(ZERO_ADDRESS);
          });

          it("emits only a transfer event", async function() {
            expectEvent.inLogs(logs, "Transfer", {
              from: owner,
              to: owner,
              itemId: itemId
            });
          });

          it("keeps the owner balance", async function() {
            expect(await item.balanceOf(owner)).to.be.bignumber.equal("2");
          });

          it("keeps same items by index", async function() {
            if (!item.itemOfOwnerByIndex) return;
            const itemsListed = await Promise.all(
              [0, 1].map(i => item.itemOfOwnerByIndex(owner, i, 1))
            );
            expect(itemsListed.map(t => t.toNumber())).to.have.members([
              firstItemId.toNumber(),
              secondItemId.toNumber()
            ]);
          });
        });

        context(
          "when the address of the previous owner is incorrect",
          function() {
            it("reverts", async function() {
              await expectRevert.unspecified(
                transferFunction.call(this, other, other, itemId, {
                  from: owner
                })
              );
            });
          }
        );

        context(
          "when the sender is not authorized for the item id",
          function() {
            it("reverts", async function() {
              await expectRevert.unspecified(
                transferFunction.call(this, owner, other, itemId, {
                  from: other
                })
              );
            });
          }
        );

        context("when the given item ID does not exist", function() {
          it("reverts", async function() {
            await expectRevert.unspecified(
              transferFunction.call(this, owner, other, nonExistentItemId, {
                from: owner
              })
            );
          });
        });

        context(
          "when the address to transfer the item to is the zero address",
          function() {
            it("reverts", async function() {
              await expectRevert.unspecified(
                transferFunction.call(this, owner, ZERO_ADDRESS, itemId, {
                  from: owner
                })
              );
            });
          }
        );
      };

      describe("via transferFrom", function() {
        shouldTransferItemsByUsers721(function(from, to, itemId, opts) {
          return item.transferFrom(from, to, itemId, opts);
        });
      });

      describe("via safeTransferFrom of ERC721", function() {
        const safeTransferFromWithData = function(from, to, itemId, opts) {
          return item.methods[
            "safeTransferFrom(address,address,uint256,bytes)"
          ](from, to, itemId, data, opts);
        };

        const safeTransferFromWithoutData = function(from, to, itemId, opts) {
          return item.methods["safeTransferFrom(address,address,uint256)"](
            from,
            to,
            itemId,
            opts
          );
        };

        const shouldTransferSafely = function(transferFun, data) {
          describe("to a user account", function() {
            shouldTransferItemsByUsers721(transferFun);
          });

          describe("to a valid receiver contract", function() {
            beforeEach(async function() {
              this.receiver = await ERC721ReceiverMock.new(
                ERC721RECEIVER_MAGIC_VALUE,
                false
              );
              other = this.receiver.address;
            });

            shouldTransferItemsByUsers721(transferFun);

            it("should call onERC721Received", async function() {
              const receipt = await transferFun.call(
                this,
                owner,
                this.receiver.address,
                itemId,
                { from: owner }
              );

              await expectEvent.inTransaction(
                receipt.tx,
                ERC721ReceiverMock,
                "Received",
                {
                  operator: owner,
                  from: owner,
                  itemId: itemId,
                  data: data
                }
              );
            });

            it("should call onERC721Received from approvedTransfer", async function() {
              const receipt = await transferFun.call(
                this,
                owner,
                this.receiver.address,
                itemId,
                { from: approvedTransfer }
              );

              await expectEvent.inTransaction(
                receipt.tx,
                ERC721ReceiverMock,
                "Received",
                {
                  operator: approvedTransfer,
                  from: owner,
                  itemId: itemId,
                  data: data
                }
              );
            });

            describe("with an invalid item id", function() {
              it("reverts", async function() {
                await expectRevert(
                  transferFun.call(
                    this,
                    owner,
                    this.receiver.address,
                    unknownItemId,
                    { from: owner }
                  ),
                  "ERC721: operator query for nonexistent item"
                );
              });
            });
          });
        };

        describe("with data", function() {
          shouldTransferSafely(safeTransferFromWithData, data);
        });

        describe("without data", function() {
          shouldTransferSafely(safeTransferFromWithoutData, null);
        });

        describe("to a receiver contract returning unexpected value", function() {
          it("reverts", async function() {
            const invalidReceiver = await ERC721ReceiverMock.new("0x42", false);
            await expectRevert(
              item.safeTransferFrom(owner, invalidReceiver.address, itemId, {
                from: owner
              }),
              "ERC721: transfer to non ERC721Receiver implementer"
            );
          });
        });

        describe("to a receiver contract that throws", function() {
          it("reverts", async function() {
            const invalidReceiver = await ERC721ReceiverMock.new(
              ERC721RECEIVER_MAGIC_VALUE,
              true
            );
            await expectRevert(
              item.safeTransferFrom(owner, invalidReceiver.address, itemId, {
                from: owner
              }),
              "ERCXReceiverMock: reverting"
            );
          });
        });

        describe("to a contract that does not implement the required function", function() {
          it("reverts", async function() {
            const invalidReceiver = item;
            await expectRevert.unspecified(
              item.safeTransferFrom(owner, invalidReceiver.address, itemId, {
                from: owner
              })
            );
          });
        });
      });
    });

    /*
    it("Should be able to transfer a non fungible item", async () => {
      const uid = 0;
      await card.mint(uid, alice);

      const balanceOf1 = await card.balanceOf.call(alice, uid);
      balanceOf1.should.be.eq.BN(new BN(1));

      const balanceOf2 = await card.balanceOf.call(alice);
      balanceOf2.should.be.eq.BN(new BN(1));

      const tx2 = await safeTransferFromNoDataNFT(card, alice, bob, uid, {
        from: alice
      });

      const ownerOf2 = await card.ownerOf(uid);
      assert.equal(ownerOf2, bob);

      assertEventVar(tx2, "Transfer", "from", alice);
      assertEventVar(tx2, "Transfer", "to", bob);
      assertEventVar(tx2, "Transfer", "itemId", uid);

      const balanceOf3 = await card.balanceOf.call(bob);
      balanceOf3.should.be.eq.BN(new BN(1));
    });

    it("Should Alice authorize transfer from Bob", async () => {
      const uid = 0;
      const amount = 5;
      await card.mint(uid, alice, amount);
      let tx = await card.setApprovalForAll(bob, true, { from: alice });

      assertEventVar(tx, "ApprovalForAll", "owner", alice);
      assertEventVar(tx, "ApprovalForAll", "operator", bob);
      assertEventVar(tx, "ApprovalForAll", "approved", true);

      tx = await safeTransferFromNoDataFT(card, alice, bob, uid, amount, {
        from: bob
      });

      assertEventVar(tx, "TransferWithQuantity", "from", alice);
      assertEventVar(tx, "TransferWithQuantity", "to", bob);
      assertEventVar(tx, "TransferWithQuantity", "itemId", uid);
      assertEventVar(tx, "TransferWithQuantity", "quantity", amount);
    });

    it("Should Carlos not be authorized to spend", async () => {
      const uid = 0;
      const amount = 5;
      let tx = await card.setApprovalForAll(bob, true, { from: alice });

      assertEventVar(tx, "ApprovalForAll", "owner", alice);
      assertEventVar(tx, "ApprovalForAll", "operator", bob);
      assertEventVar(tx, "ApprovalForAll", "approved", true);

      await expectThrow(
        safeTransferFromNoDataFT(card, alice, bob, uid, amount, {
          from: carlos
        })
      );
    });

    it("Should get the correct number of coins owned by a user", async () => {
      let numItems = await card.totalSupply();
      let balanceOf = await card.balanceOf(alice);
      balanceOf.should.be.eq.BN(new BN(0));

      await card.mint(1000, alice, 100);
      let numItems1 = await card.totalSupply();

      numItems1.should.be.eq.BN(numItems.add(new BN(1)));

      await card.mint(11, bob, 5);
      let numItems2 = await card.totalSupply();
      numItems2.should.be.eq.BN(numItems1.add(new BN(1)));

      await card.mint(12, alice, 2);
      let numItems3 = await card.totalSupply();
      numItems3.should.be.eq.BN(numItems2.add(new BN(1)));

      await card.mint(13, alice);
      let numItems4 = await card.totalSupply();
      numItems4.should.be.eq.BN(numItems3.add(new BN(1)));
      balanceOf = await card.balanceOf(alice);
      balanceOf.should.be.eq.BN(new BN(3));

      const itemsOwned = await card.itemsOwned(alice);
      const indexes = itemsOwned[0];
      const balances = itemsOwned[1];

      indexes[0].should.be.eq.BN(new BN(1000));
      indexes[1].should.be.eq.BN(new BN(12));
      indexes[2].should.be.eq.BN(new BN(13));

      balances[0].should.be.eq.BN(new BN(100));
      balances[1].should.be.eq.BN(new BN(2));
      balances[2].should.be.eq.BN(new BN(1));
    });

    it("Should update balances of sender and receiver and ownerOf for NFTs", async () => {
      //       bins :   -- 0 --  ---- 1 ----  ---- 2 ----  ---- 3 ----
      let cards = []; //[0,1,2,3, 16,17,18,19, 32,33,34,35, 48,49,50,51];
      let copies = []; //[0,1,2,3, 12,13,14,15, 11,12,13,14, 11,12,13,14];

      let nCards = 100;

      //Minting enough copies for transfer for each cards
      for (let i = 300; i < nCards + 300; i++) {
        await card.mint(i, alice);
        cards.push(i);
        copies.push(1);
      }

      const tx = await card.batchTransferFrom(alice, bob, cards, copies, {
        from: alice
      });

      let balanceFrom;
      let balanceTo;
      let ownerOf;

      for (let i = 0; i < cards.length; i++) {
        balanceFrom = await card.balanceOf(alice, cards[i]);
        balanceTo = await card.balanceOf(bob, cards[i]);
        ownerOf = await card.ownerOf(cards[i]);

        balanceFrom.should.be.eq.BN(0);
        balanceTo.should.be.eq.BN(1);
        assert.equal(ownerOf, bob);
      }

      assertEventVar(tx, "BatchTransfer", "from", alice);
      assertEventVar(tx, "BatchTransfer", "to", bob);
    });

    it("Should be able to mint a non-fungible item", async () => {
      const uid = 0;
      await card.mint(uid, accounts[0]);

      const balanceOf1 = await card.balanceOf.call(accounts[0], uid);
      balanceOf1.should.be.eq.BN(new BN(1));

      const balanceOf2 = await card.balanceOf.call(accounts[0]);
      balanceOf2.should.be.eq.BN(new BN(1));

      const ownerOf = await card.ownerOf.call(uid);
      ownerOf.should.be.eq.BN(accounts[0]);
    });

    it("Should be impossible to mint NFT items with duplicate itemId", async () => {
      const uid = 0;
      await card.mint(uid, alice);
      const supplyPostMint = await card.totalSupply();
      await expectThrow(card.mint(uid, alice));
      const supplyPostSecondMint = await card.totalSupply();
      supplyPostMint.should.be.eq.BN(supplyPostSecondMint);
    });

    it("Should be impossible to mint NFT items more than once even when owner is the contract itself", async () => {
      const uid = 0;
      await card.mint(uid, card.address);
      const supplyPostMint = await card.totalSupply();
      await expectThrow(card.mint(uid, card.address, 3));
      const supplyPostSecondMint = await card.totalSupply();
      supplyPostMint.should.be.eq.BN(supplyPostSecondMint);
    });
    
    describe("itemURI", function() {
      it("should returns the URI of the item specifed by the given ID", async function() {
        expect(await item.itemURI(firstItemId)).to.be.equal(
          "https://example.com"
        );
      });
    });
    */
  });
});
