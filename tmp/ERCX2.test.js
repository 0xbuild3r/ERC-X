require("@openzeppelin/test-helpers/configure")({
  provider: web3.currentProvider,
  singletons: { abstraction: "truffle" }
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

const Item = artifacts.require("./contracts/ERCX/Mock/ERCXFullmock.sol");
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
    user,
    newOwner,
    approvedTransfer,
    approvedTransfer2,
    approvedLien,
    lien,
    approvedTenantRight,
    tenantRight,
    operator,
    operator2,
    other
  ] = otherAccounts;

  const name = "TEST";
  const symbol = "TST";

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
      await item.mint(owner, firstItemId, {
        from: minter
      });
      await item.mint(owner, secondItemId, {
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

      context("when the given layer was higher than layer 2", function() {
        it("returns 0", async function() {
          expect(await item.balanceOf(owner, 3)).to.be.bignumber.equal("0");
        });
      });

      context("when querying the zero address of layer2", function() {
        it("throws", async function() {
          await expectRevert.unspecified(item.balanceOf(ZERO_ADDRESS, 2));
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
        "when the given item ID was tracked by this item but layer was higher than 2",
        function() {
          const itemId = firstItemId;
          it("returns the owner of the given item ID ERCX in layer4", async function() {
            await expectRevert.unspecified(await item.ownerOf(itemId, 3));
          });
        }
      );
    });

    describe("transfers in ERCX", function() {
      const itemId = firstItemId;
      let logs = null;

      describe("Layer 1", function() {
        const layer = 1;

        beforeEach(async function() {
          await item.safeTransferFrom(owner, user, itemId, layer, {
            from: owner
          });
          await item.approve(approvedTransfer, itemId, { from: owner });
          await item.setApprovalForAll(operator, true, { from: user });
          await item.setApprovalForAll(operator2, true, { from: owner });
        });

        const transferWasSuccessfulX = function({
          owner,
          itemId,
          layer,
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

        const shouldTransferItemsByUsersX = function(transferFunction) {
          context("when called by the user", function() {
            beforeEach(async function() {
              ({ logs } = await transferFunction.call(
                this,
                user,
                other,
                itemId,
                layer,
                { from: user }
              ));
            });
            transferWasSuccessfulX({
              owner,
              itemId,
              layer,
              approvedTransfer
            });
          });

          context("when called by the owner", function() {
            beforeEach(async function() {
              ({ logs } = await transferFunction.call(
                this,
                user,
                other,
                itemId,
                layer,
                { from: owner }
              ));
            });
            transferWasSuccessfulX({
              owner,
              itemId,
              layer,
              approvedTransfer
            });
          });

          context("when called by the approvedTransfer individual", function() {
            beforeEach(async function() {
              ({ logs } = await transferFunction.call(
                this,
                user,
                other,
                itemId,
                layer,
                { from: approvedTransfer }
              ));
            });
            transferWasSuccessfulX({
              owner,
              itemId,
              layer,
              approvedTransfer
            });
          });

          context("when called by the operator", function() {
            beforeEach(async function() {
              ({ logs } = await transferFunction.call(
                this,
                user,
                other,
                itemId,
                layer,
                { from: operator }
              ));
            });
            transferWasSuccessfulX({
              owner,
              itemId,
              layer,
              approvedTransfer
            });
          });

          context(
            "when called by the owner without an approvedTransfer user",
            function() {
              beforeEach(async function() {
                await item.approve(ZERO_ADDRESS, itemId, { from: owner });
                ({ logs } = await transferFunction.call(
                  this,
                  user,
                  other,
                  itemId,
                  layer,
                  { from: owner }
                ));
              });
              transferWasSuccessfulX({
                owner,
                itemId,
                layer,
                approvedTransfer: null
              });
            }
          );

          context("when sent to the owner", function() {
            beforeEach(async function() {
              await item.safeTransferFrom(owner, user, itemId, 2);
              ({ logs } = await transferFunction.call(
                this,
                owner,
                owner,
                itemId,
                layer,
                { from: owner }
              ));
            });

            it("keeps ownership of the item", async function() {
              expect(await item.ownerOf(itemId, layer)).to.be.equal(owner);
            });

            it("clears the approval for the item ID", async function() {
              expect(await item.getApproved(itemId, layer)).to.be.equal(
                ZERO_ADDRESS
              );
            });

            it("emits only a transfer event", async function() {
              expectEvent.inLogs(logs, "Transfer", {
                from: owner,
                to: owner,
                itemId: itemId,
                layer: layer
              });
            });

            it("keeps the owner balance", async function() {
              expect(await item.balanceOf(owner, layer)).to.be.bignumber.equal(
                "2"
              );
            });

            it("keeps same items by index", async function() {
              if (!item.itemOfOwnerByIndex) return;
              const itemsListed = await Promise.all(
                [0, 1].map(i => item.itemOfOwnerByIndex(owner, i, layer))
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

        const safeTransferFromWithData = function(
          from,
          to,
          itemId,
          layer,
          opts
        ) {
          return item.methods[
            "safeTransferFrom(address,address,uint256,uint256,bytes)"
          ](from, to, itemId, layer, data, opts);
        };

        const safeTransferFromWithoutData = function(
          from,
          to,
          itemId,
          layer,
          opts
        ) {
          return item.methods[
            "safeTransferFrom(address,address,uint256,uint256)"
          ](from, to, itemId, layer, opts);
        };

        const shouldTransferSafely = function(transferFun, data) {
          describe("to a user account", function() {
            shouldTransferItemsByUsersX(transferFun);
          });

          describe("to a valid receiver contract", function() {
            beforeEach(async function() {
              this.receiver = await ERCXReceiverMock.new(
                ERCXRECEIVER_MAGIC_VALUE,
                false
              );
              const owner = this.receiver.address;
            });

            shouldTransferItemsByUsersX(transferFun);

            it("should call onERCXReceived", async function() {
              const receipt = await transferFun.call(
                this,
                owner,
                this.receiver.address,
                itemId,
                layer,
                { from: owner }
              );

              await expectEvent.inTransaction(
                receipt.tx,
                ERCXReceiverMock,
                "Received",
                {
                  operator: owner,
                  from: owner,
                  tokenId: itemId,
                  layer: layer,
                  data: data
                }
              );
            });

            it("should call onERCXReceived from approvedTransfer", async function() {
              const receipt = await transferFun.call(
                this,
                owner,
                this.receiver.address,
                itemId,
                layer,
                { from: approvedTransfer }
              );

              await expectEvent.inTransaction(
                receipt.tx,
                ERCXReceiverMock,
                "Received",
                {
                  operator: approvedTransfer,
                  from: owner,
                  tokenId: itemId,
                  layer: layer,
                  data: data
                }
              );
            });

            describe("with an invalid item id", function() {
              it("reverts", async function() {
                await expectRevert.unspecified(
                  transferFun.call(
                    this,
                    owner,
                    this.receiver.address,
                    nonExistentItemId,
                    layer,
                    { from: owner }
                  )
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
            const invalidReceiver = await ERCXReceiverMock.new("0x42", false);
            await expectRevert(
              item.safeTransferFrom(
                owner,
                invalidReceiver.address,
                itemId,
                layer,
                data,
                {
                  from: owner
                }
              ),
              "ERCX: transfer to non ERCXReceiver implementer"
            );
          });
        });

        describe("to a receiver contract that throws", function() {
          it("reverts", async function() {
            const invalidReceiver = await ERCXReceiverMock.new(
              ERCXRECEIVER_MAGIC_VALUE,
              true
            );
            await expectRevert(
              item.safeTransferFrom(
                owner,
                invalidReceiver.address,
                itemId,
                layer,
                data,
                {
                  from: owner
                }
              ),
              "ERCXReceiverMock: reverting"
            );
          });
        });

        describe("to a contract that does not implement the required function", function() {
          it("reverts", async function() {
            const invalidReceiver = item;
            await expectRevert.unspecified(
              item.safeTransferFrom(
                owner,
                invalidReceiver.address,
                itemId,
                layer,
                data,
                {
                  from: owner
                }
              )
            );
          });
        });
      });
    });
    /*
    describe("approve in ERCX", function() {
      const itemId = firstItemId;

      let logs = null;

      const itClearsApproval = function() {
        it("clears approval for the item", async function() {
          expect(await item.getApproved(itemId)).to.be.equal(ZERO_ADDRESS);
        });
      };

      const itApproves = function(address) {
        it("sets the approval for the target address", async function() {
          expect(await item.getApproved(itemId)).to.be.equal(address);
        });
      };

      const itEmitsApprovalEvent = function(address) {
        it("emits an approval event", async function() {
          expectEvent.inLogs(logs, "Approval", {
            owner: owner,
            approved: address,
            itemId: itemId
          });
        });
      };

      context("when clearing approval", function() {
        context("when there was no prior approval", function() {
          beforeEach(async function() {
            ({ logs } = await item.approve(ZERO_ADDRESS, itemId, {
              from: owner
            }));
          });

          itClearsApproval();
          itEmitsApprovalEvent(ZERO_ADDRESS);
        });

        context("when there was a prior approval", function() {
          beforeEach(async function() {
            await item.approve(approvedTransfer, itemId, { from: owner });
            ({ logs } = await item.approve(ZERO_ADDRESS, itemId, {
              from: owner
            }));
          });

          itClearsApproval();
          itEmitsApprovalEvent(ZERO_ADDRESS);
        });
      });

      context("when approving a non-zero address", function() {
        context("when there was no prior approval", function() {
          beforeEach(async function() {
            ({ logs } = await item.approve(approvedTransfer, itemId, {
              from: owner
            }));
          });

          itApproves(approvedTransfer);
          itEmitsApprovalEvent(approvedTransfer);
        });

        context(
          "when there was a prior approval to the same address",
          function() {
            beforeEach(async function() {
              await item.approve(approvedTransfer, itemId, { from: owner });
              ({ logs } = await item.approve(approvedTransfer, itemId, {
                from: owner
              }));
            });

            itApproves(approvedTransfer);
            itEmitsApprovalEvent(approvedTransfer);
          }
        );

        context(
          "when there was a prior approval to a different address",
          function() {
            beforeEach(async function() {
              await item.approve(approvedTransfer2, itemId, { from: owner });
              ({ logs } = await item.approve(approvedTransfer2, itemId, {
                from: owner
              }));
            });

            itApproves(approvedTransfer2);
            itEmitsApprovalEvent(approvedTransfer2);
          }
        );
      });

      context(
        "when the address that receives the approval is the owner",
        function() {
          it("reverts", async function() {
            await expectRevert.unspecified(
              item.approve(owner, itemId, { from: owner })
            );
          });
        }
      );

      context("when the sender does not own the given item ID", function() {
        it("reverts", async function() {
          await expectRevert.unspecified(
            item.approve(approvedTransfer, itemId, { from: other })
          );
        });
      });

      context(
        "when the sender is approved for the given item ID",
        function() {
          it("reverts", async function() {
            await item.approve(approvedTransfer, itemId, { from: owner });
            await expectRevert.unspecified(
              item.approve(approvedTransfer2, itemId, {
                from: approvedTransfer
              })
            );
          });
        }
      );

      context("when the sender is an operator", function() {
        beforeEach(async function() {
          await item.setApprovalForAll(operator, true, { from: owner });
          ({ logs } = await item.approve(approvedTransfer, itemId, {
            from: operator
          }));
        });

        itApproves(approvedTransfer);
        itEmitsApprovalEvent(approvedTransfer);
      });

      context("when the given item ID does not exist", function() {
        it("reverts", async function() {
          await expectRevert.unspecified(
            item.approve(approvedTransfer, nonExistentItemId, {
              from: operator
            })
          );
        });
      });
    });

    describe("getApproved in ERCX", async function() {
      context("when item is not minted", async function() {
        it("reverts", async function() {
          await expectRevert.unspecified(
            item.getApproved(nonExistentItemId, { from: minter })
          );
        });
      });

      context("when item has been minted ", async function() {
        it("should return the zero address", async function() {
          expect(await item.getApproved(firstItemId)).to.be.equal(
            ZERO_ADDRESS
          );
        });

        context("when account has been approvedTransfer", async function() {
          beforeEach(async function() {
            await item.approve(approvedTransfer, firstItemId, {
              from: owner
            });
          });

          it("should return approvedTransfer account", async function() {
            expect(await item.getApproved(firstItemId)).to.be.equal(
              approvedTransfer
            );
          });
        });
      });
    });

    describe("setApprovalForAll in ERCX & ERC721", function() {
      context(
        "when the operator willing to approve is not the owner",
        function() {
          context(
            "when there is no operator approval set by the sender",
            function() {
              it("approves the operator", async function() {
                await item.setApprovalForAll(operator, true, { from: owner });

                expect(await item.isApprovedForAll(owner, operator)).to.equal(
                  true
                );
              });

              it("emits an approval event", async function() {
                const { logs } = await item.setApprovalForAll(
                  operator,
                  true,
                  {
                    from: owner
                  }
                );

                expectEvent.inLogs(logs, "ApprovalForAll", {
                  owner: owner,
                  operator: operator,
                  approved: true
                });
              });
            }
          );

          context("when the operator was set as not approved", function() {
            beforeEach(async function() {
              await item.setApprovalForAll(operator, false, { from: owner });
            });

            it("approves the operator", async function() {
              await item.setApprovalForAll(operator, true, { from: owner });

              expect(await item.isApprovedForAll(owner, operator)).to.equal(
                true
              );
            });

            it("emits an approval event", async function() {
              const { logs } = await item.setApprovalForAll(operator, true, {
                from: owner
              });

              expectEvent.inLogs(logs, "ApprovalForAll", {
                owner: owner,
                operator: operator,
                approved: true
              });
            });

            it("can unset the operator approval", async function() {
              await item.setApprovalForAll(operator, false, { from: owner });

              expect(await item.isApprovedForAll(owner, operator)).to.equal(
                false
              );
            });
          });

          context("when the operator was already approved", function() {
            beforeEach(async function() {
              await item.setApprovalForAll(operator, true, { from: owner });
            });

            it("keeps the approval to the given address", async function() {
              await item.setApprovalForAll(operator, true, { from: owner });

              expect(await item.isApprovedForAll(owner, operator)).to.equal(
                true
              );
            });

            it("emits an approval event", async function() {
              const { logs } = await item.setApprovalForAll(operator, true, {
                from: owner
              });

              expectEvent.inLogs(logs, "ApprovalForAll", {
                owner: owner,
                operator: operator,
                approved: true
              });
            });
          });
        }
      );

      context("when the operator is the owner", function() {
        it("reverts", async function() {
          await expectRevert.unspecified(
            item.setApprovalForAll(owner, true, { from: owner })
          );
        });
      });
    });
    */

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
                { from: owner }
              ));
            });
            transferWasSuccessful721({
              owner,
              itemId,
              approvedTransfer: null
            });
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
                  tokenId: itemId,
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
                  tokenId: itemId,
                  data: data
                }
              );
            });

            describe("with an invalid item id", function() {
              it("reverts", async function() {
                await expectRevert.unspecified(
                  transferFun.call(
                    this,
                    owner,
                    this.receiver.address,
                    nonExistentItemId,
                    { from: owner }
                  )
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
              item.safeTransferFrom(
                owner,
                invalidReceiver.address,
                itemId,
                data,
                {
                  from: owner
                }
              ),
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
              item.safeTransferFrom(
                owner,
                invalidReceiver.address,
                itemId,
                data,
                {
                  from: owner
                }
              ),
              "ERC721ReceiverMock: reverting"
            );
          });
        });

        describe("to a contract that does not implement the required function", function() {
          it("reverts", async function() {
            const invalidReceiver = item;
            await expectRevert.unspecified(
              item.safeTransferFrom(
                owner,
                invalidReceiver.address,
                itemId,
                data,
                {
                  from: owner
                }
              )
            );
          });
        });
      });
    });

    describe("approve in ERC721", function() {
      const itemId = firstItemId;

      let logs = null;

      const itClearsApproval = function() {
        it("clears approval for the item", async function() {
          expect(await item.getApproved(itemId)).to.be.equal(ZERO_ADDRESS);
        });
      };

      const itApproves = function(address) {
        it("sets the approval for the target address", async function() {
          expect(await item.getApproved(itemId)).to.be.equal(address);
        });
      };

      const itEmitsApprovalEvent = function(address) {
        it("emits an approval event", async function() {
          expectEvent.inLogs(logs, "Approval", {
            owner: owner,
            approved: address,
            itemId: itemId
          });
        });
      };

      context("when clearing approval", function() {
        context("when there was no prior approval", function() {
          beforeEach(async function() {
            ({ logs } = await item.approve(ZERO_ADDRESS, itemId, {
              from: owner
            }));
          });

          itClearsApproval();
          itEmitsApprovalEvent(ZERO_ADDRESS);
        });

        context("when there was a prior approval", function() {
          beforeEach(async function() {
            await item.approve(approvedTransfer, itemId, { from: owner });
            ({ logs } = await item.approve(ZERO_ADDRESS, itemId, {
              from: owner
            }));
          });

          itClearsApproval();
          itEmitsApprovalEvent(ZERO_ADDRESS);
        });
      });

      context("when approving a non-zero address", function() {
        context("when there was no prior approval", function() {
          beforeEach(async function() {
            ({ logs } = await item.approve(approvedTransfer, itemId, {
              from: owner
            }));
          });

          itApproves(approvedTransfer);
          itEmitsApprovalEvent(approvedTransfer);
        });

        context(
          "when there was a prior approval to the same address",
          function() {
            beforeEach(async function() {
              await item.approve(approvedTransfer, itemId, { from: owner });
              ({ logs } = await item.approve(approvedTransfer, itemId, {
                from: owner
              }));
            });

            itApproves(approvedTransfer);
            itEmitsApprovalEvent(approvedTransfer);
          }
        );

        context(
          "when there was a prior approval to a different address",
          function() {
            beforeEach(async function() {
              await item.approve(approvedTransfer2, itemId, { from: owner });
              ({ logs } = await item.approve(approvedTransfer2, itemId, {
                from: owner
              }));
            });

            itApproves(approvedTransfer2);
            itEmitsApprovalEvent(approvedTransfer2);
          }
        );
      });

      context(
        "when the address that receives the approval is the owner",
        function() {
          it("reverts", async function() {
            await expectRevert.unspecified(
              item.approve(owner, itemId, { from: owner })
            );
          });
        }
      );

      context("when the sender does not own the given item ID", function() {
        it("reverts", async function() {
          await expectRevert.unspecified(
            item.approve(approvedTransfer, itemId, { from: other })
          );
        });
      });

      context("when the sender is approved for the given item ID", function() {
        it("reverts", async function() {
          await item.approve(approvedTransfer, itemId, { from: owner });
          await expectRevert.unspecified(
            item.approve(approvedTransfer2, itemId, {
              from: approvedTransfer
            })
          );
        });
      });

      context("when the sender is an operator", function() {
        beforeEach(async function() {
          await item.setApprovalForAll(operator, true, { from: owner });
          ({ logs } = await item.approve(approvedTransfer, itemId, {
            from: operator
          }));
        });

        itApproves(approvedTransfer);
        itEmitsApprovalEvent(approvedTransfer);
      });

      context("when the given item ID does not exist", function() {
        it("reverts", async function() {
          await expectRevert.unspecified(
            item.approve(approvedTransfer, nonExistentItemId, {
              from: operator
            })
          );
        });
      });
    });

    describe("getApproved in ERC721", async function() {
      context("when item is not minted", async function() {
        it("reverts", async function() {
          await expectRevert.unspecified(
            item.getApproved(nonExistentItemId, { from: minter })
          );
        });
      });

      context("when item has been minted ", async function() {
        it("should return the zero address", async function() {
          expect(await item.getApproved(firstItemId)).to.be.equal(ZERO_ADDRESS);
        });

        context("when account has been approvedTransfer", async function() {
          beforeEach(async function() {
            await item.approve(approvedTransfer, firstItemId, {
              from: owner
            });
          });

          it("should return approvedTransfer account", async function() {
            expect(await item.getApproved(firstItemId)).to.be.equal(
              approvedTransfer
            );
          });
        });
      });
    });

    describe("Metadata", function() {
      it("has a name", async function() {
        expect(await item.name()).to.be.equal(name);
      });

      it("has a symbol", async function() {
        expect(await item.symbol()).to.be.equal(symbol);
      });

      describe("item URI", function() {
        const baseURI = "https://api.com/v1/";
        const sampleUri = "mock://myitem";

        it("it is empty by default", async function() {
          expect(await item.itemURI(firstItemId)).to.be.equal("");
        });

        it("reverts when queried for non existent item id", async function() {
          await expectRevert(
            item.itemURI(nonExistentItemId),
            "URI query for nonexistent item"
          );
        });

        it("can be set for a item id", async function() {
          await item.setItemURI(firstItemId, sampleUri);
          expect(await item.itemURI(firstItemId)).to.be.equal(sampleUri);
        });

        it("reverts when setting for non existent item id", async function() {
          await expectRevert.unspecified(
            item.setItemURI(nonExistentItemId, sampleUri)
          );
        });

        it("base URI can be set", async function() {
          await item.setBaseURI(baseURI);
          expect(await item.baseURI()).to.equal(baseURI);
        });

        it("base URI is added as a prefix to the item URI", async function() {
          await item.setBaseURI(baseURI);
          await item.setItemURI(firstItemId, sampleUri);

          expect(await item.itemURI(firstItemId)).to.be.equal(
            baseURI + sampleUri
          );
        });

        it("item URI can be changed by changing the base URI", async function() {
          await item.setBaseURI(baseURI);
          await item.setItemURI(firstItemId, sampleUri);

          const newBaseURI = "https://api.com/v2/";
          await item.setBaseURI(newBaseURI);
          expect(await item.itemURI(firstItemId)).to.be.equal(
            newBaseURI + sampleUri
          );
        });

        it("item URI is empty for items with no URI but with base URI", async function() {
          await item.setBaseURI(baseURI);

          expect(await item.itemURI(firstItemId)).to.be.equal("");
        });

        it("items with URI can be burnt ", async function() {
          await item.setItemURI(firstItemId, sampleUri);

          await item.burn(firstItemId, { from: owner });

          expect(await item.exists(firstItemId)).to.equal(false);
          await expectRevert.unspecified(item.itemURI(firstItemId));
        });
      });
    });

    describe("totalNumberOfItems", function() {
      it("returns total item supply", async function() {
        expect(await item.totalNumberOfItems()).to.be.bignumber.equal("2");
      });
    });

    describe("itemOfOwnerByIndex", function() {
      describe("when the given index is lower than the amount of items owned by the given address", function() {
        it("returns the item ID placed at the given index", async function() {
          expect(
            await item.itemOfOwnerByIndex(owner, 1, 0)
          ).to.be.bignumber.equal(firstItemId);
        });
      });

      describe("when the index is greater than or equal to the total items owned by the given address", function() {
        it("reverts", async function() {
          await expectRevert.unspecified(item.itemOfOwnerByIndex(owner, 1, 10));
        });
      });

      describe("when the given address does not own any item", function() {
        it("reverts", async function() {
          await expectRevert.unspecified(item.itemOfOwnerByIndex(other, 1, 0));
        });
      });
    });

    describe("itemByIndex", function() {
      it("should return all items", async function() {
        const itemsListed = await Promise.all(
          [0, 1].map(i => item.itemByIndex(i))
        );
        expect(itemsListed.map(t => t.toNumber())).to.have.members([
          firstItemId.toNumber(),
          secondItemId.toNumber()
        ]);
      });

      it("should revert if index is greater than supply", async function() {
        await expectRevert.unspecified(item.itemByIndex(2));
      });

      [firstItemId, secondItemId].forEach(function(itemId) {
        it(`should return all items after burning item ${itemId} and minting new items`, async function() {
          const newItemId = new BN(300);
          const anotherNewItemId = new BN(400);

          await item.burn(itemId, { from: owner });
          await item.mint(newOwner, newItemId, { from: minter });
          await item.mint(newOwner, anotherNewItemId, { from: minter });

          expect(await item.totalNumberOfItems()).to.be.bignumber.equal("3");

          const itemsListed = await Promise.all(
            [0, 1, 2].map(i => item.itemByIndex(i))
          );
          const expectedItems = [
            firstItemId,
            secondItemId,
            newItemId,
            anotherNewItemId
          ].filter(x => x !== itemId);
          expect(itemsListed.map(t => t.toNumber())).to.have.members(
            expectedItems.map(t => t.toNumber())
          );
        });
      });
    });

    describe("mint", function() {
      let logs = null;

      describe("when successful", function() {
        beforeEach(async function() {
          const result = await item.mint(newOwner, thirdItemId, {
            from: minter
          });
          logs = result.logs;
        });

        it("assigns the item to the new owner", async function() {
          expect(await item.ownerOf(thirdItemId, 1)).to.equal(newOwner);
        });

        it("increases the balance of its owner", async function() {
          expect(await item.balanceOf(newOwner, 1)).to.be.bignumber.equal("1");
        });

        it("emits a transfer and minted event", async function() {
          expectEvent.inLogs(logs, "Transfer", {
            from: ZERO_ADDRESS,
            to: newOwner,
            itemId: thirdItemId
          });
        });
      });

      describe("when the given owner address is the zero address", function() {
        it("reverts", async function() {
          await expectRevert.unspecified(
            item.mint(ZERO_ADDRESS, thirdItemId, { from: minter })
          );
        });
      });

      describe("when the given item ID was already tracked by this contract", function() {
        it("reverts", async function() {
          await expectRevert.unspecified(
            item.mint(owner, firstItemId, { from: minter })
          );
        });
      });
    });

    describe("mintWithItemURI", function() {
      const MOCK_URI = "MOCKURI";
      it("can mint with a itemUri", async function() {
        await item.mintWithItemURI(newOwner, thirdItemId, MOCK_URI, {
          from: minter
        });
      });
    });

    describe("burn", function() {
      const itemId = firstItemId;
      let logs = null;

      describe("when successful", function() {
        beforeEach(async function() {
          const result = await item.burn(itemId, { from: owner });
          logs = result.logs;
        });

        it("burns the given item ID and adjusts the balance of the owner", async function() {
          await expectRevert.unspecified(item.ownerOf(itemId));
          expect(await item.balanceOf(owner)).to.be.bignumber.equal("1");
        });

        it("emits a burn event", async function() {
          expectEvent.inLogs(logs, "Transfer", {
            from: owner,
            to: ZERO_ADDRESS,
            itemId: itemId
          });
        });
      });

      describe("when the given item ID was not tracked by this contract", function() {
        it("reverts", async function() {
          await expectRevert.unspecified(
            item.burn(nonExistentItemId, { from: creator })
          );
        });
      });
    });
  });
});
