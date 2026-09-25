# Composer Remediation Report

Date: 3 October 2026

## Scope

This remediation addresses the audit findings against `AnubisMultiHopComposer` and aligns Anubis-side WBTC/XAUt token precision with their Ethereum assets. The XAUt Anubis peer was replaced without changing its Ethereum Adapter or Composer route. Owner/delegate migration to a Safe and token-issuer operational approvals remain separate follow-up work.

## Active deployment

- Contract: `AnubisMultiHopComposerV2`
- Ethereum address: [`0x3C496D3a94f8D44cdf01dCBcb49863A5eec39840`](https://etherscan.io/address/0x3C496D3a94f8D44cdf01dCBcb49863A5eec39840#code)
- Deployment transaction: [`0x8c20bde9fe0d2da81c5c0608a25a43645a4805df371d1f6a74d0edfc539d445c`](https://etherscan.io/tx/0x8c20bde9fe0d2da81c5c0608a25a43645a4805df371d1f6a74d0edfc539d445c)
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
- Route configuration transaction: [`0xaac2634cb36ecc9652bb1f27702f8f9eab7384f108d75799fc3847d51da11438`](https://etherscan.io/tx/0xaac2634cb36ecc9652bb1f27702f8f9eab7384f108d75799fc3847d51da11438)
- Destination configuration transaction: [`0x5d2a87652859ba1e4967c7198cb5a29f6d7ca38452781dbca3c736f3b153b80c`](https://etherscan.io/tx/0x5d2a87652859ba1e4967c7198cb5a29f6d7ca38452781dbca3c736f3b153b80c)
- Previous Composer destination-disable transaction: [`0xe83b0fbee17f8cf7b292a17392111eb25e69c7a3fa713652e5cb5e0516ab77db`](https://etherscan.io/tx/0xe83b0fbee17f8cf7b292a17392111eb25e69c7a3fa713652e5cb5e0516ab77db)
- Previous Composer route-disable transaction: [`0x6ab36d694f634169041475f194e4dc0a3ae90fc55a86a3cfd0b6a16e8f7d118f`](https://etherscan.io/tx/0x6ab36d694f634169041475f194e4dc0a3ae90fc55a86a3cfd0b6a16e8f7d118f)
- Active Composer token balances after configuration: zero for every configured underlying
- Active Composer native balance after configuration: zero

## Verification and tests

- Solidity compilation: passed with Solidity `0.8.22`, optimizer 200 runs.
- Project regression suite: 14 tests passed, covering successful hop 2, actual credited amount, dust refund, permanent send failure, zero-fee and one-wei-short permissionless executions, empty-reason retry, disabled and removed routes, standard nested compose, malformed/non-EVM payloads, slippage failure, backed claim fallback and owner surplus isolation.
- This review repository includes six independently reproducible security regression tests for zero-fee execution, one-wei fee shortfall, empty-reason retry, the OFT-independent route kill switch, zero-address protection and claim backing. Run them with `pnpm test`.
- Ethereum runtime, owner, Endpoint, configuration read-back and source verification: passed.
- Mainnet configuration and balance read-back: passed.
- No production token transfer was sent. The configured test account had no official-mesh token suitable for a closed-loop Composer test; injecting reserves solely for testing was intentionally avoided. A Stargate/LZ-originated micro-transfer should be performed after integration review and before route launch.

## Remaining launch gates

1. Transfer Owner/Delegate roles to the approved Safe/timelock.
2. Complete issuer and compliance confirmation for Ondo assets.
