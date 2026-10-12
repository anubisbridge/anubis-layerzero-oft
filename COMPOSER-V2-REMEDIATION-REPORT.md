# Composer Remediation Report

Date: 13 October 2026

## Scope

This remediation addresses the audit findings against `AnubisMultiHopComposer` and aligns Anubis-side WBTC/XAUt token precision with their Ethereum assets. The XAUt Anubis peer was replaced without changing its Ethereum Adapter or Composer route. Owner/delegate migration to a Safe and token-issuer operational approvals remain separate follow-up work.

## Active deployment

- Contract: `AnubisMultiHopComposerV2`
- Ethereum address: [`0x58BEbbB0e17Fef8a740C56Cf50FfAd819488AaDB`](https://etherscan.io/address/0x58BEbbB0e17Fef8a740C56Cf50FfAd819488AaDB#code)
- Deployment transaction: [`0x4281791b88ff9c0d260bd7a48766af24a03db14c714a1bb58fd88bb4361d8c87`](https://etherscan.io/tx/0x4281791b88ff9c0d260bd7a48766af24a03db14c714a1bb58fd88bb4361d8c87)
- Endpoint: `0x1a44076050125825900e736c501f859c50fE728c`
- Owner: `0x59Dc82A7Ee06d825035D444A9064e8307Fa7977a`
- Etherscan source verification: passed

## Findings and remediation

### H-1 — Permanent token lock after Composer failure: remediated

- The standard LayerZero payload remains `abi.encode(nextHopParam)`; no custom Stargate payload is required.
- Hop 2 uses the amount actually credited by hop 1 instead of requiring the user-provided `amountLD` to match exactly.
- `quoteOFT` is used before sending, preserving final `minAmountLD` protection and accounting for dust or OFT fees.
- Protocol-level failures that cannot safely identify the received asset still revert for LayerZero retry.
- An underfunded permissionless `lzCompose` execution reverts with `InsufficientNativeFee`; it cannot consume the message or force a local refund.
- Empty-reason failures, including gas-starved or unexplained second-hop execution, revert and remain retryable.
- Business-level hop-2 failures stop on Ethereum. The Composer attempts to return the received token and unused native fee locally to the EVM address in `nextHop.to`.
- A malformed payload falls back to an EVM-formatted `composeFrom` address.
- If an ERC-20 pause, blocklist or receiver behavior prevents automatic local refund, the amount becomes claimable by the same refund account.
- Owner surplus recovery cannot withdraw balances reserved for user claims.
- A claim cannot be recorded unless the Composer's current token balance fully backs all existing claims plus the new claim.
- Existing routes can be disabled without relying on the external OFTs remaining responsive, and `removeRoute()` provides a hard kill switch whose pending messages remain retryable.
- No automatic reverse cross-chain refund is attempted.

The resulting model is: `Retry → local automatic refund on the failure chain → user claim fallback`.

### ANU-02 — Partial refund withdrawal and authorized alternate recipient: remediated

- Refund withdrawal functions now take an explicit amount and support partial withdrawals.
- Direct claimant withdrawals advance the corresponding nonce, preventing signature replay across the direct and delegated paths.
- EIP-712 signatures, EOA 64/65-byte signatures, ERC-1271 validation, reentrancy protection and fully backed liability accounting remain enforced.
- A claimant cannot withdraw more than its recorded token or native refund balance, and no unsigned third-party redirection path is exposed.

### ANU-06 — Canonical EVM recipient validation: remediated

Before quoting or sending hop 2, the Composer validates `nextHop.to` as a canonical EVM address. Zero addresses and `bytes32` values with non-zero upper 96 bits are rejected, preventing silent truncation to an unintended recipient. A regression test covers malformed non-canonical recipients.

### N-2 — Same-address refund for contract recipients: constrained

The standard `abi.encode(SendParam)` payload has no independent Ethereum refund-address field. To preserve Stargate/lzAsset compatibility, the Composer does not add a custom payload field. Integrators must restrict or warn contract recipients (including Safe and AA accounts) unless the recipient is known to control the same address on Ethereum. Invalid or non-EVM refund addresses revert instead of creating an unreachable claim.

### N-3 — Route shutdown dependency: remediated

An existing route can be disabled without calling either OFT, and `removeRoute()` provides a hard kill switch. A removed route reverts compose execution so the message remains retryable if the route is restored.

### N-4 — Compose gas: operationally increased

The integration request now requires at least 800,000 `lzCompose` gas for the Ethereum Hub Composer, with a higher dynamically estimated value permitted. Gas-starved and empty-reason failures revert instead of entering the refund branch.

### H-2 — Concentrated owner/delegate authority: acknowledged, deferred

No permission migration was performed in this scope. Owner and Endpoint delegate migration to a Safe/timelock is planned separately. This does not require another Composer redeployment.

### M-1 — Underlying Adapter transfer behavior: reviewed and accepted

The Composer uses the hop-1 actual credited amount and hop-2 `OFTReceipt`. USDT and PAXG retain LayerZero's standard `OFTAdapter` behavior, consistent with the official Stargate/LayerZero implementation pattern; no custom strict-transfer accounting is introduced. Ethereum USDT currently reports zero transfer fee, and the reviewed PAXG implementation does not expose an ordinary transfer-fee mechanism. Token fee parameters, upgrades, pauses, freezes and blocklists remain operational monitoring items. A material behavior change requires the affected route to be paused and reassessed before accepting new deposits.

### M-2 — Ondo issuer behavior and restrictions: operational follow-up

No on-chain evidence of active rebasing was identified. Third-party custody permission, freeze/allowlist behavior, corporate actions and transfer eligibility still require issuer/business confirmation before reserves are deposited or routes are launched.

### M-3 — `approvalRequired()` compatibility: closed as not reproducible

The 15 reviewed Ondo Ethereum OFTs return `approvalRequired() == false` and use their authorized burn path. Reviewed Adapter-style OFTs return `true`. The Composer supports both cases.

### Informational findings

- The Ethereum Hub comment was corrected.
- Standard nested `composeMsg` remains supported for destination-chain logic. A downstream Composer sees the Ethereum Composer as its immediate `composeFrom`; applications needing the original identity must carry and validate it in their own destination payload.
- WBTC uses 8 local decimals and `sharedDecimals=8` on both Ethereum and Anubis, so no chain-specific decimal handling is required.
- XAUt uses 6 local decimals and `sharedDecimals=6` on both Ethereum and Anubis, so no chain-specific decimal handling is required.
- Anubis fee DAI and bridged OFT DAI remain separate contracts with the same symbol and must be distinguished by contract address and wallet metadata.

## Configuration migration

- Active routes copied and read back: 40
- Active destination allowlist entries copied and read back: 71
- Route configuration transaction: [`0x9230344100a5bac83581a90d0dff062d4f948b52529ea3aff028a8ff0c667284`](https://etherscan.io/tx/0x9230344100a5bac83581a90d0dff062d4f948b52529ea3aff028a8ff0c667284)
- Destination configuration transaction: [`0xb0adbb62b6780fe0dfdca5ab56e1bdc598efa88f3ab59582efdfbc9785f813a2`](https://etherscan.io/tx/0xb0adbb62b6780fe0dfdca5ab56e1bdc598efa88f3ab59582efdfbc9785f813a2)
- Previous Composer destination-disable transaction: [`0xc062d52967efbd076da716205bb14fabf9094fe3cf08074ddf3fda17956031af`](https://etherscan.io/tx/0xc062d52967efbd076da716205bb14fabf9094fe3cf08074ddf3fda17956031af)
- Previous Composer route-disable transaction: [`0x7e5b1d24274e65b2db4f7e31743f18e1c9563d1a17eff0a6df4965582167e8b7`](https://etherscan.io/tx/0x7e5b1d24274e65b2db4f7e31743f18e1c9563d1a17eff0a6df4965582167e8b7)
- Active Composer token balances after configuration: zero for every configured underlying
- Active Composer native balance after configuration: zero

## Verification and tests

- Solidity compilation: passed with Solidity `0.8.22`, optimizer 200 runs.
- Private project regression suite: 16 tests passed, covering successful hop 2, actual credited amount, dust refund, permanent send failure, zero-fee and one-wei-short permissionless executions, empty-reason retry, disabled and removed routes, standard nested compose, malformed/non-EVM payloads, non-canonical EVM recipients, slippage failure, backed claim fallback, alternate recipient authorization and owner surplus isolation.
- This review repository includes 15 independently reproducible regression tests covering the same security properties, including zero-fee execution, one-wei fee shortfall, empty-reason retry, the OFT-independent route kill switch, non-canonical recipient protection and claim backing. Run them with `pnpm test`.
- Ethereum runtime, owner, Endpoint, configuration read-back and source verification: passed.
- Mainnet configuration and balance read-back: passed.
- No production token transfer was sent. The configured test account had no official-mesh token suitable for a closed-loop Composer test; injecting reserves solely for testing was intentionally avoided. A Stargate/LZ-originated micro-transfer should be performed after integration review and before route launch.

## Remaining launch gates

1. Transfer Owner/Delegate roles to the approved Safe/timelock.
2. Complete issuer and compliance confirmation for Ondo assets.
