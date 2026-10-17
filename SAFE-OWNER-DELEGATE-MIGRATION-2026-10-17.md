# Production Owner / Endpoint Delegate Migration

Date: 17 October 2026

The production permission migration was completed after the Safe addresses and membership were verified on-chain. No Safe SDK test transaction was used in this migration.

## Safe targets

- Ethereum: `0x8893335CB1d4638020c66A88C08726373F119169`, threshold `2/3`
- Anubis: `0xC78E137279E245E8Da0C09C60F56bB695cb35358`, threshold `2/3`

## Scope

- 28 Ethereum OApps: 27 `OFTAdapter` contracts and one native ETH `NativeOFTAdapter`
- 28 Anubis `OFTAlt` contracts
- 1 Ethereum `AnubisMultiHopComposerV2`
- Total: 57 production contracts

## Migration order

1. The current Owner EOA set the LayerZero Endpoint delegate to the corresponding chain Safe on all 56 OApps.
2. Delegate values were read back before ownership was changed.
3. The current Owner EOA transferred ownership of all 56 OApps and the Ethereum Composer to the corresponding chain Safe.
4. Final on-chain read-back confirmed all 57 Owners and all 56 OApp delegates.

## Result

- Ethereum OApp Owner and Endpoint delegate: `0x8893335CB1d4638020c66A88C08726373F119169`
- Anubis OApp Owner and Endpoint delegate: `0xC78E137279E245E8Da0C09C60F56bB695cb35358`
- Ethereum Composer Owner: `0x8893335CB1d4638020c66A88C08726373F119169`
- Owner verification: `57/57` passed
- Endpoint delegate verification: `56/56` passed

Detailed transaction hashes and read-back data are included in [`safe-owner-delegate-migration-2026-10-17.json`](safe-owner-delegate-migration-2026-10-17.json).

The three Safe owners and the `2/3` threshold are unchanged. Future Owner-controlled configuration changes must be proposed and executed through the corresponding Safe with two owner signatures.
