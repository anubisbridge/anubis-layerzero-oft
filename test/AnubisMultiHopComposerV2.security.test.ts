import { expect } from "chai";
import { ethers } from "hardhat";

describe("AnubisMultiHopComposerV2", function () {
  async function fixture() {
    const [owner, refund, recipient] = await ethers.getSigners();
    const Token = await ethers.getContractFactory("MockComposerToken");
    const token = await Token.deploy();
    const Endpoint = await ethers.getContractFactory("MockComposerEndpoint");
    const endpoint = await Endpoint.deploy();
    const Oft = await ethers.getContractFactory("MockComposerOFT");
    const source = await Oft.deploy(token.address, endpoint.address, false);
    const next = await Oft.deploy(token.address, endpoint.address, true);
    const Composer = await ethers.getContractFactory("AnubisMultiHopComposerV2");
    const composer = await Composer.deploy(endpoint.address, owner.address);
    await composer.setRoute(source.address, token.address, next.address, true);
    await composer.setDestination(next.address, 30465, true);
    return { owner, refund, recipient, token, endpoint, source, next, composer };
  }

  function sendParam(to: string, amountLD = 999, minAmountLD = 990, composeMsg = "0x") {
    return { dstEid: 30465, to: ethers.utils.hexZeroPad(to, 32), amountLD, minAmountLD, extraOptions: "0x", composeMsg, oftCmd: "0x" };
  }

  async function message(composeFrom: string, amount: number, param: any) {
    const payload = ethers.utils.defaultAbiCoder.encode(
      ["tuple(uint32 dstEid,bytes32 to,uint256 amountLD,uint256 minAmountLD,bytes extraOptions,bytes composeMsg,bytes oftCmd)"],
      [param]
    );
    return ethers.utils.solidityPack(
      ["uint64", "uint32", "uint256", "bytes32", "bytes"],
      [1, 30102, amount, ethers.utils.hexZeroPad(composeFrom, 32), payload]
    );
  }

  async function expectRevert(promise: Promise<unknown>, selector?: string) {
    let reverted = false;
    try {
      await promise;
    } catch (error: any) {
      reverted = true;
      if (selector) {
        const data = error?.data ?? error?.error?.data ?? error?.error?.error?.data ?? "";
        expect(String(data).slice(0, 10)).to.equal(selector);
      }
    }
    expect(reverted).to.equal(true);
  }

  it("uses actual received amount, sends the dust-free amount and directly refunds dust/native excess", async () => {
    const f = await fixture();
    const amount = 1001;
    await f.token.mint(f.composer.address, amount);
    const msg = await message(f.refund.address, amount, sendParam(f.recipient.address));
    const fee = await f.next.nativeFee();
    const extra = ethers.utils.parseEther("0.0002");
    await f.endpoint.compose(f.composer.address, f.source.address, ethers.constants.HashZero, msg, { value: fee.add(extra) });
    expect((await f.token.balanceOf(f.next.address)).toString()).to.equal("1000");
    expect((await f.token.balanceOf(f.recipient.address)).toString()).to.equal("1");
    expect((await f.composer.tokenRefunds(f.token.address, f.recipient.address)).toString()).to.equal("0");
    expect((await f.composer.nativeRefunds(f.recipient.address)).toString()).to.equal("0");
  });

  it("directly refunds tokens and native fee when the second hop permanently fails", async () => {
    const f = await fixture();
    await f.next.setFailSend(true);
    await f.token.mint(f.composer.address, 1000);
    const msg = await message(f.refund.address, 1000, sendParam(f.recipient.address));
    const fee = await f.next.nativeFee();
    const receipt = await (await f.endpoint.compose(f.composer.address, f.source.address, ethers.constants.HashZero, msg, { value: fee })).wait();
    expect(receipt.logs.some((log: any) => log.address.toLowerCase() === f.composer.address.toLowerCase())).to.equal(true);
    expect((await f.token.balanceOf(f.recipient.address)).toString()).to.equal("1000");
    expect((await ethers.provider.getBalance(f.composer.address)).toString()).to.equal("0");
  });

  it("rejects a permissionless zero-fee execution and remains executable with the quoted fee", async () => {
    const f = await fixture();
    await f.token.mint(f.composer.address, 1000);
    const guid = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("zero-fee-retry"));
    const msg = await message(f.refund.address, 1000, sendParam(f.recipient.address));
    const selector = ethers.utils.id("InsufficientNativeFee(uint256,uint256)").slice(0, 10);

    await expectRevert(f.endpoint.compose(f.composer.address, f.source.address, guid, msg), selector);
    expect((await f.token.balanceOf(f.composer.address)).toString()).to.equal("1000");
    expect((await f.token.balanceOf(f.recipient.address)).toString()).to.equal("0");

    await f.endpoint.compose(f.composer.address, f.source.address, guid, msg, { value: await f.next.nativeFee() });
    expect((await f.token.balanceOf(f.next.address)).toString()).to.equal("1000");
    expect((await f.token.balanceOf(f.composer.address)).toString()).to.equal("0");
  });

  it("rejects an execution that is one wei short without refunding the transfer", async () => {
    const f = await fixture();
    await f.token.mint(f.composer.address, 1000);
    const msg = await message(f.refund.address, 1000, sendParam(f.recipient.address));
    const fee = await f.next.nativeFee();

    await expectRevert(
      f.endpoint.compose(f.composer.address, f.source.address, ethers.constants.HashZero, msg, { value: fee.sub(1) })
    );
    expect((await f.token.balanceOf(f.composer.address)).toString()).to.equal("1000");
    expect((await f.token.balanceOf(f.recipient.address)).toString()).to.equal("0");
  });

  it("keeps an empty-reason second-hop failure retryable instead of refunding", async () => {
    const f = await fixture();
    await f.next.setFailSendWithoutReason(true);
    await f.token.mint(f.composer.address, 1000);
    const msg = await message(f.refund.address, 1000, sendParam(f.recipient.address));

    await expectRevert(
      f.endpoint.compose(f.composer.address, f.source.address, ethers.constants.HashZero, msg, {
        value: await f.next.nativeFee(),
      })
    );
    expect((await f.token.balanceOf(f.composer.address)).toString()).to.equal("1000");
    expect((await f.token.balanceOf(f.recipient.address)).toString()).to.equal("0");
  });

  it("refunds a registered route after it is disabled", async () => {
    const f = await fixture();
    await f.composer.setRoute(f.source.address, f.token.address, f.next.address, false);
    await f.token.mint(f.composer.address, 1000);
    const msg = await message(f.refund.address, 1000, sendParam(f.recipient.address));
    await f.endpoint.compose(f.composer.address, f.source.address, ethers.constants.HashZero, msg, { value: await f.next.nativeFee() });
    expect((await f.token.balanceOf(f.recipient.address)).toString()).to.equal("1000");
  });

  it("removes a route without external OFT calls and keeps the transfer pending", async () => {
    const f = await fixture();
    await f.composer.removeRoute(f.source.address);
    await f.token.mint(f.composer.address, 1000);
    const msg = await message(f.refund.address, 1000, sendParam(f.recipient.address));

    await expectRevert(f.endpoint.compose(f.composer.address, f.source.address, ethers.constants.HashZero, msg));
    expect((await f.token.balanceOf(f.composer.address)).toString()).to.equal("1000");
    expect((await f.token.balanceOf(f.recipient.address)).toString()).to.equal("0");
  });

  it("preserves a standard nested compose payload for destination-chain handling", async () => {
    const f = await fixture();
    await f.token.mint(f.composer.address, 1000);
    const msg = await message(f.refund.address, 1000, sendParam(f.recipient.address, 1000, 990, "0x12"));
    await f.endpoint.compose(f.composer.address, f.source.address, ethers.constants.HashZero, msg, { value: await f.next.nativeFee() });
    expect((await f.token.balanceOf(f.recipient.address)).toString()).to.equal("0");
    expect((await f.token.balanceOf(f.next.address)).toString()).to.equal("1000");
  });

  it("refunds malformed payloads to composeFrom", async () => {
    const f = await fixture();
    await f.token.mint(f.composer.address, 1000);
    const legacyPayload = "0x1234";
    const msg = ethers.utils.solidityPack(
      ["uint64", "uint32", "uint256", "bytes32", "bytes"],
      [1, 30102, 1000, ethers.utils.hexZeroPad(f.refund.address, 32), legacyPayload]
    );
    await f.endpoint.compose(f.composer.address, f.source.address, ethers.constants.HashZero, msg, {
      value: await f.next.nativeFee(),
    });
    expect((await f.token.balanceOf(f.refund.address)).toString()).to.equal("1000");
  });

  it("rejects a malformed payload when composeFrom is not an EVM address", async () => {
    const f = await fixture();
    await f.token.mint(f.composer.address, 1000);
    const nonEvmSender = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("non-evm-sender"));
    const msg = ethers.utils.solidityPack(
      ["uint64", "uint32", "uint256", "bytes32", "bytes"],
      [1, 30102, 1000, nonEvmSender, "0x1234"]
    );
    await expectRevert(f.endpoint.compose(f.composer.address, f.source.address, ethers.constants.HashZero, msg));
    expect((await f.composer.tokenRefunds(f.token.address, ethers.constants.AddressZero)).toString()).to.equal("0");
    expect((await f.token.balanceOf(f.composer.address)).toString()).to.equal("1000");
  });

  it("refunds when the quoted second-hop amount violates final slippage", async () => {
    const f = await fixture();
    await f.next.setDust(20);
    await f.token.mint(f.composer.address, 1000);
    const msg = await message(f.refund.address, 1000, sendParam(f.recipient.address, 1, 990));
    await f.endpoint.compose(f.composer.address, f.source.address, ethers.constants.HashZero, msg, {
      value: await f.next.nativeFee(),
    });
    expect((await f.token.balanceOf(f.recipient.address)).toString()).to.equal("1000");
    expect((await f.token.balanceOf(f.next.address)).toString()).to.equal("0");
  });

  it("creates a claimable fallback protected from owner recovery only if automatic local refund fails", async () => {
    const f = await fixture();
    await f.token.setBlocked(f.recipient.address, true);
    await f.next.setFailSend(true);
    await f.token.mint(f.composer.address, 1000);
    const msg = await message(f.refund.address, 1000, sendParam(f.recipient.address));
    await f.endpoint.compose(f.composer.address, f.source.address, ethers.constants.HashZero, msg, {
      value: await f.next.nativeFee(),
    });
    expect((await f.composer.tokenRefunds(f.token.address, f.recipient.address)).toString()).to.equal("1000");
    let reverted = false;
    try { await f.composer.recoverSurplus(f.token.address, f.owner.address, 1); } catch { reverted = true; }
    expect(reverted).to.equal(true);
    await f.token.setBlocked(f.recipient.address, false);
    await f.composer.connect(f.recipient).withdrawTokenRefund(f.token.address);
    expect((await f.token.balanceOf(f.recipient.address)).toString()).to.equal("1000");
  });

  it("never records a token claim that is not backed by the Composer balance", async () => {
    const f = await fixture();
    await f.token.setBlocked(f.recipient.address, true);
    await f.next.setFailSend(true);
    await f.token.mint(f.composer.address, 1000);
    await expectRevert(f.composer.recoverSurplus(f.token.address, f.owner.address, 1000));
    const msg = await message(f.refund.address, 1000, sendParam(f.recipient.address));

    await f.endpoint.compose(f.composer.address, f.source.address, ethers.constants.HashZero, msg, {
      value: await f.next.nativeFee(),
    });
    expect((await f.composer.tokenRefunds(f.token.address, f.recipient.address)).toString()).to.equal("1000");
    expect((await f.composer.totalTokenRefunds(f.token.address)).toString()).to.equal("1000");
  });

  it("allows a claimant to authorize an alternate token refund recipient", async () => {
    const f = await fixture();
    await f.token.setBlocked(f.recipient.address, true);
    await f.next.setFailSend(true);
    await f.token.mint(f.composer.address, 1000);
    const msg = await message(f.refund.address, 1000, sendParam(f.recipient.address));
    await f.endpoint.compose(f.composer.address, f.source.address, ethers.constants.HashZero, msg, {
      value: await f.next.nativeFee(),
    });

    const network = await ethers.provider.getNetwork();
    const deadline = (await ethers.provider.getBlock("latest")).timestamp + 3600;
    const domain = {
      name: "Anubis MultiHop Composer",
      version: "1",
      chainId: network.chainId,
      verifyingContract: f.composer.address,
    };
    const types = {
      TokenRefund: [
        { name: "token", type: "address" },
        { name: "claimant", type: "address" },
        { name: "recipient", type: "address" },
        { name: "amount", type: "uint256" },
        { name: "nonce", type: "uint256" },
        { name: "deadline", type: "uint256" },
      ],
    };
    const value = {
      token: f.token.address,
      claimant: f.recipient.address,
      recipient: f.owner.address,
      amount: 1000,
      nonce: 0,
      deadline,
    };
    const signature = await f.recipient._signTypedData(domain, types, value);
    await f.composer.withdrawTokenRefundTo(
      f.token.address,
      f.recipient.address,
      f.owner.address,
      1000,
      deadline,
      signature
    );
    expect((await f.token.balanceOf(f.owner.address)).toString()).to.equal("1000");
    expect((await f.composer.totalTokenRefunds(f.token.address)).toString()).to.equal("0");
  });

  async function contractRefundFixture() {
    const f = await fixture();
    const Wallet = await ethers.getContractFactory("MockERC1271Wallet");
    const wallet = await Wallet.deploy();
    await f.token.setBlocked(wallet.address, true);
    await f.next.setFailSend(true);
    await f.token.mint(f.composer.address, 1000);
    const msg = await message(wallet.address, 1000, sendParam(wallet.address));
    await f.endpoint.compose(f.composer.address, f.source.address, ethers.constants.HashZero, msg, {
      value: await f.next.nativeFee(),
    });
    return { ...f, wallet };
  }

  async function contractRefundDeadline(f: any) {
    return (await ethers.provider.getBlock("latest")).timestamp + 3600;
  }

  it("accepts only a complete ABI-encoded ERC-1271 magic value", async () => {
    const f = await contractRefundFixture();
    await f.wallet.setReturnData(ethers.utils.defaultAbiCoder.encode(["bytes4"], ["0x1626ba7e"]));
    const deadline = await contractRefundDeadline(f);
    await f.composer.withdrawTokenRefundTo(f.token.address, f.wallet.address, f.owner.address, 1000, deadline, "0x");
    expect((await f.token.balanceOf(f.owner.address)).toString()).to.equal("1000");
  });

  for (const [name, returnData] of [
    ["truncated 4-byte", "0x1626ba7e"],
    ["magic prefix with trailing data", "0x1626ba7e00"],
    ["overlong ABI data", "0x" + "1626ba7e" + "00".repeat(60)],
    ["wrong magic", ethers.utils.defaultAbiCoder.encode(["bytes4"], ["0xffffffff"])],
  ] as const) {
    it(`rejects ERC-1271 ${name} return data`, async () => {
      const f = await contractRefundFixture();
      await f.wallet.setReturnData(returnData);
      const deadline = await contractRefundDeadline(f);
      await expectRevert(
        f.composer.withdrawTokenRefundTo(f.token.address, f.wallet.address, f.owner.address, 1000, deadline, "0x")
      );
      expect((await f.composer.tokenRefundNonces(f.wallet.address)).toString()).to.equal("0");
    });
  }

  it("rejects a reverting ERC-1271 wallet", async () => {
    const f = await contractRefundFixture();
    await f.wallet.setShouldRevert(true);
    const deadline = await contractRefundDeadline(f);
    await expectRevert(
      f.composer.withdrawTokenRefundTo(f.token.address, f.wallet.address, f.owner.address, 1000, deadline, "0x")
    );
    expect((await f.composer.tokenRefundNonces(f.wallet.address)).toString()).to.equal("0");
  });

  it("uses a native refund ledger when a receiver rejects ETH", async () => {
    const f = await fixture();
    const Reject = await ethers.getContractFactory("RejectNativeRefund");
    const reject = await Reject.deploy();
    await f.next.setFailSend(true);
    await f.token.mint(f.composer.address, 1000);
    const msg = await message(f.refund.address, 1000, sendParam(reject.address));
    const fee = await f.next.nativeFee();
    await f.endpoint.compose(f.composer.address, f.source.address, ethers.constants.HashZero, msg, { value: fee });
    expect((await f.composer.nativeRefunds(reject.address)).toString()).to.equal(fee.toString());
    expect((await f.composer.totalNativeRefunds()).toString()).to.equal(fee.toString());
  });
});
