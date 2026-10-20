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

## WBTC8 follow-up

On 20 October 2026, a follow-up read-back identified that the 17 October batch had migrated the retired 18-decimal WBTC contract instead of the current 8-decimal WBTC OFTAlt. The active WBTC8 contract, `0x287A0E98feC5c41fbaf53B63882a602a24d21640`, was corrected without redeployment:

- Endpoint delegate transaction: [`0xe094fc454249ff851b56b9cb2e452ab5537200acfcbcf2310a65603b1dd03fce`](https://anubisscan.io/tx/0xe094fc454249ff851b56b9cb2e452ab5537200acfcbcf2310a65603b1dd03fce)
- Ownership transfer transaction: [`0xc7824e5fc8d60df9fb59039862550ef903329df04c10e0252d2457c631061fe4`](https://anubisscan.io/tx/0xc7824e5fc8d60df9fb59039862550ef903329df04c10e0252d2457c631061fe4)
- Final Owner and Endpoint delegate: `0xC78E137279E245E8Da0C09C60F56bB695cb35358`

The correction and final read-back are recorded in [`wbtc8-safe-owner-delegate-migration-2026-10-20.json`](wbtc8-safe-owner-delegate-migration-2026-10-20.json). A fresh on-chain audit then confirmed all 28 Ethereum Adapters and all 28 active Anubis OFTAlt contracts use their corresponding 2/3 Safe as both Owner and Endpoint delegate.

The three Safe owners and the `2/3` threshold are unchanged. Future Owner-controlled configuration changes must be proposed and executed through the corresponding Safe with two owner signatures.
