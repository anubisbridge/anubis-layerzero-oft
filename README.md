# Anubis LayerZero OFT / Stargate Technical Review

Date: 3 October 2026

Hello LayerZero / Stargate team,

Anubis requests a technical configuration review only. Please do not list or activate any route until a second launch confirmation is received from the Anubis team.

## Final architecture

- Anubis: 28 newly deployed `OFTAlt` contracts, required because the Anubis Endpoint charges LayerZero messaging fees in ERC-20 DAI.
- Ethereum: 27 self-hosted lock/release `OFTAdapter` contracts and one `NativeOFTAdapter` for native ETH.
- Ethereum: one Composer (`AnubisMultiHopComposerV2`) for compatible existing official OFT meshes.
- Each Anubis OFT has exactly one active project-managed peer: its corresponding Ethereum Adapter at EID `30101`.
- Self-managed BSC, Polygon, Solana, Tron, Avalanche and HyperEVM pathways have been retired. Their peers to Anubis EID `30465` were cleared after confirming zero reserves.
- Remote-chain coverage is requested only where an existing compatible official OFT mesh can compose through Ethereum. We do not request self-managed liquidity on those remote chains.

Topology:

`official OFT mesh → Ethereum Composer → Ethereum Adapter ⇄ Anubis OFTAlt`

Ethereum-origin transfers use the Adapter directly. Native ETH uses the Ethereum `NativeOFTAdapter` directly.

## Requested coverage

Direct Ethereum ⇄ Anubis routes are requested for all 28 assets below.

Additional official-mesh routes currently configured through the Ethereum Composer are:

- WBTC: BSC, Avalanche, Optimism, Base, Sei, Unichain, Swell, Berachain and HyperEVM ⇄ Ethereum Composer ⇄ Anubis.
- USDT0: Polygon, Arbitrum, Optimism, X Layer, Sei, Flare, Unichain, Rootstock, Ink, Berachain and HyperEVM ⇄ Ethereum Composer ⇄ Anubis.
- USDe: BSC, Avalanche, Arbitrum, Optimism, Mantle, Base, Blast, Fraxtal, Zircuit, Morph and Berachain ⇄ Ethereum Composer ⇄ Anubis.
- XAUt0: Avalanche, Polygon, Arbitrum and HyperEVM ⇄ Ethereum Composer ⇄ Anubis.
- LINK0: HyperEVM ⇄ Ethereum Composer ⇄ Anubis.
- Ondo Stocks: BSC ⇄ Ethereum Composer ⇄ Anubis for all 15 listed stocks.

No self-managed BSC, Polygon, Solana, Tron, Avalanche or HyperEVM route is included in this request. Any additional official-mesh route must be confirmed and enabled separately.

## Network contracts

| Network | Chain ID | EID | Endpoint | Role |
| --- | ---: | ---: | --- | --- |
| Ethereum | 1 | 30101 | `0x1a44076050125825900e736c501f859c50fE728c` | Canonical lockbox hub |
| Anubis | 6714 | 30465 | `0x76111de813f83aaadbd62773bf41247634e2319a` | `OFTAlt` destination |

- Ethereum Composer: [`0x3C496D3a94f8D44cdf01dCBcb49863A5eec39840`](https://etherscan.io/address/0x3C496D3a94f8D44cdf01dCBcb49863A5eec39840#code)
- Owner and delegate: `0x59Dc82A7Ee06d825035D444A9064e8307Fa7977a`
- Anubis Endpoint fee token reported at deployment: `0x83fd06F0846d9D90B3016bF670Efe2E0B11cDe14`

## Asset contracts

| Asset | Ethereum underlying | Ethereum Adapter | Anubis OFTAlt |
| --- | --- | --- | --- |
| USDT | `0xdAC17F958D2ee523a2206206994597C13D831ec7` | `0xC2e75F4dB642Cf1b8b5ca9A1DC0450DaE9505352` | `0xA0bD8B3d33718F623C5C1F1551B5B069f6a4F127` |
| USDC | `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` | `0xcDDF41841f6e0D2611f8f4326f872C0490Cb50d1` | `0x283B21431130544D8DE08756313EF06A38a2a81e` |
| DAI | `0x6B175474E89094C44Da98b954EedeAC495271d0F` | `0x2E20D21CD928d662aE52eF86690043f93F14faF0` | `0x9aB7638f85eCfb449Cef84d11e2Da69694B3b792` |
| WBTC | `0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599` | `0x713441E6e7865ad91C3A89620dff1CdAd49900A6` | `0x287A0E98feC5c41fbaf53B63882a602a24d21640` |
| ETH | native ETH | `0x99c880f03055351A17bDa275E7C165fdeFF89fA5` (`NativeOFTAdapter`) | `0xf0Cf5B49E8cd02573EC2F76Ab3b357A7Eab7bE3d` |
| USD1 | `0x8d0D000Ee44948FC98c9B98A4FA4921476f08B0d` | `0x7298E75dbAF188BaA2e528188cf253C97D85B60b` | `0x820d2B28c34f87195ab32055c054Ce84d43d1360` |
| PAXG | `0x45804880De22913dAFE09f4980848ECE6EcbAf78` | `0xE44ba3562BE254045591748481789496d8B12815` | `0x7A0B1fA85d1E89116256D5250d4c368D752c3e79` |
| XAUt | `0x68749665FF8D2d112Fa859AA293F07A622782F38` | `0x1f033d91919FF79BB0FA66fcb378549F6746f03D` | `0xdDfEAA69B9351156BE245915C3f1ce45Ac7c0544` |
| USDe | `0x4c9EDD5852cd905f086C759E8383e09bff1E68B3` | `0xB93e47A4901ADcCcEae4CF7ac4cc74613aBB4cf3` | `0x6F0cA9A07690905CfbfC6c75ac8F69fCea4ebD38` |
| USDS | `0xdC035D45d973E3EC169d2276DDab16f1e407384F` | `0xC05Bf3348f2cf1b6Ec127C601D0978eC59cD6F8e` | `0xA6DB5061A613176aB8F8ae868BF22C1c3dD88363` |
| LINK | `0x514910771AF9Ca656af840dff83E8264EcF986CA` | `0x093A44369a75aFBC245680EB5B296bab9983557b` | `0x5c79e306FBEE477F0F727138080d0EAb0f7556A4` |
| UNI | `0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984` | `0xF01CFBc960A910D58dc01E5D0a57c97eCf2E5302` | `0x75112Cb111A2b51de4846cD0183545f28F6e3E16` |
| SKY | `0x56072C95FAA701256059aa122697B133aDEd9279` | `0x6e1cB391C5d3Ce8aCfa8b54E89a43166a33d39C1` | `0x1fF6Ea9AbBa7C7d9F524962A5d32899cda47655e` |

### Ondo Stocks

| Asset | Ethereum underlying | Ethereum Adapter | Anubis OFTAlt |
| --- | --- | --- | --- |
| AAPLon | `0x14c3abf95cb9c93a8b82c1cdcb76d72cb87b2d4c` | `0xbf09E3FA640dfc83C81543BC2dA7A7Ec2FA30767` | `0xc6D0778718d40f31422e60F25299A04878E8d9c2` |
| AMDon | `0x0c1f3412a44ff99e40bf14e06e5ea321ae7b3938` | `0x52386039CBC6C80B0c8B70ea9901393824e44E5e` | `0x7c2Ff3733683817b66834B29562A6AF4A70eF7F9` |
| CRCLon | `0x3632dea96a953c11dac2f00b4a05a32cd1063fae` | `0x632B01694fFadbC04b025845Ad555b1F10D64340` | `0xD578D5f983DA24F27F5506fA5285eE54778AC8FF` |
| GMEon | `0x71d24baeb0a033ec5f90ff65c4210545af378d97` | `0x871BC70C0d14015754909d71e51331454C56120d` | `0x033815B275eDA321BcCFa5487728CBc7f87bEb20` |
| GOOGLon | `0xba47214edd2bb43099611b208f75e4b42fdcfedc` | `0x301eC97e7620339A5cC955DA8f2271F613F5ba50` | `0xa37e25C021851F49A14F3490BE2C410b8A2226f8` |
| INTCon | `0xfda09936dbd717368de0835ba441d9e62069d36f` | `0xbFABbe98303B78159C15dE8CdA6c04f2213e72D1` | `0x7c29CE7AaA51C3Cc671805449a79078d926babc3` |
| MRNAon | `0xa2c1c0b4683a871187d4565eb63abf9aef5947ee` | `0xEB8C79CA79913974cB44686133ea3e451AA17ae2` | `0x551F93186CC1a123481b7BBC11D056a899d7B9e1` |
| MSFTon | `0xb812837b81a3a6b81d7cd74cfb19a7f2784555e5` | `0x78E535dD90C11a30dBadFBCb9621648236756Ca4` | `0xc8fA84483EEbF11f2A7F61ACc0417e84e7043845` |
| MSTRon | `0xcabd955322dfbf94c084929ac5e9eca3feb5556f` | `0x76B2813Ba6Bb0e1cF33908ef7C7876a2F7B457B0` | `0x0dFD1c436ddCAfe468eEa8d67e47a5BB315f389c` |
| MUon | `0x050362ab1072cb2ce74d74770e22a3203ad04ee5` | `0x57F2Bc7947AF0146c768c0C150FAA6E04776f93E` | `0x567c7f4587532FF4645D46c2546e80ADE6782B12` |
| NFLXon | `0x032dec3372f25c41ea8054b4987a7c4832cdb338` | `0x05fDe3a3CC3b77AEb39504DB812A8aa83b4C3f4d` | `0xA77609896bb3D6D4dB05D06C957CB0C611f58f31` |
| NVDAon | `0x2d1f7226bd1f780af6b9a49dcc0ae00e8df4bdee` | `0x25df0345D524c982d68f99187AB79CFC9FDEF225` | `0xcc1b7bc3dDEC73986C63E878C7C81e614d030A5d` |
| SNDKon | `0x71e2400cf1cb83204f33794ed326636a71a9aafc` | `0x00E31E70F1d2Ee4bB06c237bcd366417106DcCfb` | `0x51dbea18a37b503C1207b6B6cEB678182f72a91e` |
| SPCXon | `0xc9eef266834730340a55b6cc24621b31baf55581` | `0x88B931ad2F1d9809f786E396c467b031876ef9BB` | `0x4AB3Dab17a8607F874Cd9987ee57Fc972BEe8D04` |
| TSLAon | `0xf6b1117ec07684d3958cad8beb1b302bfd21103f` | `0x262d46113849EF2948845a9f10ee109164469c98` | `0x2700fdFfBBC8bE673e80B7faF8a302F5B5196C90` |

## Composer configuration

- Composer address: [`0x3C496D3a94f8D44cdf01dCBcb49863A5eec39840`](https://etherscan.io/address/0x3C496D3a94f8D44cdf01dCBcb49863A5eec39840#code).
- WBTC official Ethereum Adapter: `0x0555e30da8f98308edb960aa94c0db47230d2b9c`; enabled EIDs: BSC `30102`, Avalanche `30106`, Optimism `30111`, Base `30184`, Sei `30280`, Unichain `30320`, Swell `30335`, Berachain `30362` and HyperEVM `30367`.
- USDT0 official Ethereum OFT/Adapter: `0x6c96de32cea08842dcc4058c14d3aaad7fa41dee`.
- USDT0 outbound EIDs enabled: Polygon `30109`, Arbitrum `30110`, Optimism `30111`, X Layer `30274`, Sei `30280`, Flare `30295`, Unichain `30320`, Rootstock `30333`, Ink `30339`, Berachain `30362` and HyperEVM `30367`.
- USDe official Ethereum OFT: `0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34`; enabled EIDs: BSC `30102`, Avalanche `30106`, Arbitrum `30110`, Optimism `30111`, Mantle `30181`, Base `30184`, Blast `30243`, Fraxtal `30255`, Zircuit `30303`, Morph `30322` and Berachain `30362`.
- XAUt0 official Ethereum Adapter: `0xb9c2321bb7d0db468f570d10a424d1cc8efd696c`; enabled EIDs: Avalanche `30106`, Polygon `30109`, Arbitrum `30110` and HyperEVM `30367`.
- LINK0 official Ethereum Adapter: `0x8b3157e78f4ea5ad124e16f8c9df5fa27a7b0b33`; HyperEVM EID `30367` is enabled.
- The 15 official Ethereum Ondo OFTs are registered as inbound Composer sources, with BSC EID `30102` enabled for the reverse leg.
- Composer routes require the official OFT and project Adapter to return the same Ethereum underlying from `IOFT.token()`.

The additional Mesh candidates were enabled only after on-chain checks of the Ethereum and remote contracts, reciprocal peers, Endpoint V2, OFT version, shared decimals and composed-send quoting. WBTC uses 8 local decimals and `sharedDecimals=8` on both Ethereum and Anubis. XAUt uses 6 local decimals and `sharedDecimals=6` on both Ethereum and Anubis. USDe routes for Manta, Kava, Metis, Mode, Scroll, zkSync and Swell remain disabled because the full audit gate did not pass.

The Composer does not custody permanent reserves. It atomically receives the first-hop asset and forwards it through the matching Ethereum Adapter. The Ethereum Adapter is the sole project-managed lockbox for that asset.

The Composer remains compatible with the LayerZero lzAsset reference encoding: the first-hop `composeMsg` is exactly `abi.encode(nextHopParam)`, with no Anubis-specific payload fields. It uses the amount actually credited by hop 1 and applies hop-2 `quoteOFT` dust and slippage checks. An underfunded or empty-reason execution reverts and remains retryable, so permissionless `lzCompose` callers cannot force a local refund by manipulating value or gas. Other explicit business-level failures stop on Ethereum and first return the received token and unused native fee to the EVM address in `nextHop.to`; malformed payloads fall back to a valid EVM-formatted `composeFrom`. A claimable balance is created only if that local transfer itself cannot be delivered and is fully backed by the Composer balance. No automatic reverse bridge is attempted.

All 40 active route mappings and 71 destination allowlist entries were configured on the Composer and read back on-chain.

## Pathway security configuration

- Ethereum confirmations: 15; Anubis confirmations: 5.
- Required DVNs in each direction: LayerZero Labs and Horizen.
- Required DVN count: 2; optional DVNs: 0.
- Executor: official local LayerZero Executor.
- Maximum message size: 10,000 bytes.
- Enforced `lzReceive` gas: 120,000 for `SEND`.
- Enforced `lzReceive` gas: 120,000 plus 500,000 compose gas for `SEND_AND_CALL` on Anubis.
- For first-hop delivery to the Ethereum Hub Composer, quote hop 2 immediately before submission and provision at least 800,000 `lzCompose` gas; Stargate may use a higher dynamically estimated value.
- Peer encoding: the remote 20-byte EVM contract left-padded to `bytes32`.

Direct on-chain read-back of owner, Endpoint, reciprocal peer, message libraries, DVNs, Executor and enforced options passed for all 28 Ethereum ⇄ Anubis pairs. This is configuration verification, not an end-to-end asset-transfer test.

## Software versions and source verification

- Solidity `0.8.22`, optimizer enabled with 200 runs.
- `@layerzerolabs/oft-alt-evm` `0.0.5`.
- `@layerzerolabs/oapp-alt-evm` `0.0.5`.
- `@layerzerolabs/oft-evm` `4.0.1`.
- `@layerzerolabs/oapp-evm` `0.4.1`.
- `@layerzerolabs/lz-evm-protocol-v2` `3.0.168`.
- OpenZeppelin Contracts `5.6.1`.

The repository includes `package.json`, `pnpm-lock.yaml`, `hardhat.config.ts` and `tsconfig.json`. Run `pnpm install --frozen-lockfile` followed by `pnpm run compile` to reproduce the Solidity build.

The Ethereum Adapters and Composer are source-published and verified on Etherscan. The WBTC Adapter has an exact creation/runtime match on Sourcify and is also published through Routescan; Etherscan publication is pending. All 28 current Anubis `OFTAlt` contracts, including WBTC and the 6-decimal XAUt deployment, are source-verified on AnubisScan.

## Operational status and requested checks

- All new Anubis OFTs and retained Ethereum Adapters are reciprocally peered and passed configuration read-back.
- No reserves have been deposited and no end-to-end production transfer has been performed.

Please review:

1. The use of the official `OFTAlt` variant for the ERC-20-fee Anubis Endpoint.
2. The 28 Ethereum hub pairs and their security configuration.
3. The Composer mappings for the compatible WBTC, USDT0, USDe, XAUt0, LINK0 and Ondo OFT meshes.

After review, please wait for a second confirmation from the Anubis team before configuration or launch.

The Composer audit remediation and deployment evidence are documented in [COMPOSER-V2-REMEDIATION-REPORT.md](./COMPOSER-V2-REMEDIATION-REPORT.md).

Technical contact: Telegram @ROBBYABC
