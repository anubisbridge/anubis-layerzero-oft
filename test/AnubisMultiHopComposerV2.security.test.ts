import { expect } from "chai";
import { ethers } from "hardhat";

describe("AnubisMultiHopComposerV2 security regression", function () {
  async function fixture() {
    const [owner, refund, recipient] = await ethers.getSigners();
    const token = await (await ethers.getContractFactory("MockComposerToken")).deploy();
    const endpoint = await (await ethers.getContractFactory("MockComposerEndpoint")).deploy();
    const Oft = await ethers.getContractFactory("MockComposerOFT");
    const source = await Oft.deploy(token.address, endpoint.address, false);
    const next = await Oft.deploy(token.address, endpoint.address, true);
    const composer = await (await ethers.getContractFactory("AnubisMultiHopComposerV2"))
      .deploy(endpoint.address, owner.address);
    await composer.setRoute(source.address, token.address, next.address, true);
    await composer.setDestination(next.address, 30465, true);
    return { owner, refund, recipient, token, endpoint, source, next, composer };
  }

  function param(to: string) {
    return {
      dstEid: 30465,
      to: ethers.utils.hexZeroPad(to, 32),
      amountLD: 1000,
      minAmountLD: 1000,
      extraOptions: "0x",
      composeMsg: "0x",
      oftCmd: "0x",
    };
  }

  function message(from: string, p: ReturnType<typeof param>) {
    const payload = ethers.utils.defaultAbiCoder.encode(
      ["tuple(uint32 dstEid,bytes32 to,uint256 amountLD,uint256 minAmountLD,bytes extraOptions,bytes composeMsg,bytes oftCmd)"],
      [p]
    );
    return ethers.utils.solidityPack(
      ["uint64", "uint32", "uint256", "bytes32", "bytes"],
      [1, 30102, 1000, ethers.utils.hexZeroPad(from, 32), payload]
    );
  }

  async function mustRevert(promise: Promise<unknown>) {
    let reverted = false;
    try { await promise; } catch { reverted = true; }
    expect(reverted).to.equal(true);
  }

  it("keeps a zero-fee permissionless execution retryable", async () => {
    const f = await fixture();
    const msg = message(f.refund.address, param(f.recipient.address));
    await f.token.mint(f.composer.address, 1000);
    await mustRevert(f.endpoint.compose(f.composer.address, f.source.address, ethers.constants.HashZero, msg));
    expect((await f.token.balanceOf(f.composer.address)).toString()).to.equal("1000");
    await f.endpoint.compose(f.composer.address, f.source.address, ethers.constants.HashZero, msg, { value: await f.next.nativeFee() });
    expect((await f.token.balanceOf(f.next.address)).toString()).to.equal("1000");
  });

  it("does not refund an execution that is one wei short", async () => {
    const f = await fixture();
    const msg = message(f.refund.address, param(f.recipient.address));
    await f.token.mint(f.composer.address, 1000);
    await mustRevert(f.endpoint.compose(f.composer.address, f.source.address, ethers.constants.HashZero, msg, {
      value: (await f.next.nativeFee()).sub(1),
    }));
    expect((await f.token.balanceOf(f.composer.address)).toString()).to.equal("1000");
    expect((await f.token.balanceOf(f.recipient.address)).toString()).to.equal("0");
  });

  it("keeps empty-reason second-hop failures retryable", async () => {
    const f = await fixture();
    const msg = message(f.refund.address, param(f.recipient.address));
    await f.next.setFailSendWithoutReason(true);
    await f.token.mint(f.composer.address, 1000);
    await mustRevert(f.endpoint.compose(f.composer.address, f.source.address, ethers.constants.HashZero, msg, {
      value: await f.next.nativeFee(),
    }));
    expect((await f.token.balanceOf(f.composer.address)).toString()).to.equal("1000");
  });

  it("provides an OFT-independent route kill switch", async () => {
    const f = await fixture();
    await f.composer.removeRoute(f.source.address);
    const route = await f.composer.routes(f.source.address);
    expect(route.token).to.equal(ethers.constants.AddressZero);
    expect(route.enabled).to.equal(false);
  });

  it("never books a malformed non-EVM refund to the zero address", async () => {
    const f = await fixture();
    const nonEvmSender = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("non-evm-sender"));
    const msg = ethers.utils.solidityPack(
      ["uint64", "uint32", "uint256", "bytes32", "bytes"],
      [1, 30102, 1000, nonEvmSender, "0x1234"]
    );
    await f.token.mint(f.composer.address, 1000);
    await mustRevert(f.endpoint.compose(f.composer.address, f.source.address, ethers.constants.HashZero, msg));
    expect((await f.composer.tokenRefunds(f.token.address, ethers.constants.AddressZero)).toString()).to.equal("0");
  });

  it("never books a claim without sufficient token backing", async () => {
    const f = await fixture();
    const msg = message(f.refund.address, param(f.recipient.address));
    await f.next.setFailSend(true);
    await f.token.mint(f.composer.address, 1000);
    await f.composer.recoverSurplus(f.token.address, f.owner.address, 1000);
    await mustRevert(f.endpoint.compose(f.composer.address, f.source.address, ethers.constants.HashZero, msg, {
      value: await f.next.nativeFee(),
    }));
    expect((await f.composer.tokenRefunds(f.token.address, f.recipient.address)).toString()).to.equal("0");
  });
});
