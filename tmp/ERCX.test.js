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

const Item = artifacts.require("./contracts/ERCX/Contract/ERCXMintable.sol");
const ERC721ReceiverMock = artifacts.require(
  "./contracts/ERCX/Mock/ERC721Receivermock.sol"
);
const ERCXReceiverMock = artifacts.require(
  "./contracts/ERCX/Mock/ERCXReceivermock.sol"
);

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
  const ERC721RECEIVER_MAGIC_VALUE = "0x150b7a02";

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
              const owner = this.receiver.address;
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
                    nonExistentItemId,
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
  });
});
