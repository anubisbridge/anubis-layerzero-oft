# Anubis LayerZero OFT Deployment

Date: 25 September 2026

This repository documents the production LayerZero V2 OFT deployment connecting Anubis with Ethereum, BNB Smart Chain, Polygon PoS, Solana, Tron, Avalanche and HyperEVM. It uses self-hosted lock/release OFT Adapters or Native OFT Adapters on source chains and mint/burn OFTs on Anubis.

The deployment includes stablecoins, canonical Ethereum WBTC, native ETH, BNB, POL and TRX pathways, additional mainstream assets, and the same 15 Ondo Stocks pathways from Ethereum and BNB Smart Chain to shared Anubis OFTs. Contract source is published under `contracts/`; the Solana OFT Program source is published under `solana/programs/oft/`.

## Configured routes

| Asset | Routes |
| --- | --- |
| USDT | Ethereum ↔ Anubis, BSC ↔ Anubis, Polygon ↔ Anubis, Solana ↔ Anubis, Tron ↔ Anubis |
| USDC | Ethereum ↔ Anubis, BSC ↔ Anubis, Polygon ↔ Anubis, Solana ↔ Anubis |
| DAI | Ethereum ↔ Anubis, BSC ↔ Anubis, Polygon ↔ Anubis |
| WBTC | Ethereum ↔ Anubis |
| ETH | Ethereum ↔ Anubis |
| BNB | BSC ↔ Anubis |
| POL | Polygon ↔ Anubis |
| TRX | Tron ↔ Anubis |
| USD1 | Ethereum ↔ Anubis, BSC ↔ Anubis |
| PAXG | Ethereum ↔ Anubis |
| XAUt | Ethereum ↔ Anubis |
| USDe | Ethereum ↔ Anubis, BSC ↔ Anubis |
| USDS | Ethereum ↔ Anubis |
| LINK | Ethereum ↔ Anubis |
| UNI | Ethereum ↔ Anubis |
| SKY | Ethereum ↔ Anubis |
| AVAX | Avalanche ↔ Anubis |
| HYPE | HyperEVM ↔ Anubis |

The configured Ethereum/BSC ↔ Anubis Ondo Stocks pathways are `AAPLon`, `AMDon`, `CRCLon`, `GMEon`, `GOOGLon`, `INTCon`, `MRNAon`, `MSFTon`, `MSTRon`, `MUon`, `NFLXon`, `NVDAon`, `SNDKon`, `SPCXon` and `TSLAon`.

## Network configuration

| Network | Chain ID | LayerZero EID | Endpoint V2 |
| --- | ---: | ---: | --- |
| Ethereum | 1 | 30101 | `0x1a44076050125825900e736c501f859c50fE728c` |
| BNB Smart Chain | 56 | 30102 | `0x1a44076050125825900e736c501f859c50fE728c` |
| Polygon PoS | 137 | 30109 | `0x1a44076050125825900e736c501f859c50fE728c` |
| Anubis | 6714 | 30465 | `0x76111de813f83aaadbd62773bf41247634e2319a` |
| Solana Mainnet | — | 30168 | `76y77prsiCMvXMjuoZ5VRrhG5qYBrUMYTE5WgHqgjEn6` |
| Tron Mainnet | 728126428 | 30420 | `TAy9xwjYjBBN6kutzrZJaAZJHCAejjK1V9` |
| Avalanche | 43114 | 30106 | `0x1a44076050125825900e736c501f859c50fE728c` |
| HyperEVM | 999 | 30367 | `0x3a73033c0b1407574c76bdbac67f126f6b4a9aa9` |

### Additional mainstream assets

Twelve additional self-hosted Adapter ↔ Anubis OFT routes have been deployed and fully configured. USD1 and USDe each use one Anubis OFT with Ethereum and BSC peers; the other assets are one-to-one.

| Asset | Source | Underlying | Source Adapter | Anubis OFT |
| --- | --- | --- | --- | --- |
| USD1 | Ethereum | `0x8d0D000Ee44948FC98c9B98A4FA4921476f08B0d` | `0x7298E75dbAF188BaA2e528188cf253C97D85B60b` | `0x1952860adE184eFB0DeadfaD694771aeD0130736` |
| PAXG | Ethereum | `0x45804880De22913dAFE09f4980848ECE6EcbAf78` | `0xE44ba3562BE254045591748481789496d8B12815` | `0x8DB3FF1648C79150Dc62Ad8F8dFe97b9bf2278aa` |
| XAUt | Ethereum | `0x68749665FF8D2d112Fa859AA293F07A622782F38` | `0x1f033d91919FF79BB0FA66fcb378549F6746f03D` | `0xc31AB260Cd76557c0E521C0F9d15AD48964A9FC5` |
| USDe | Ethereum | `0x4c9EDD5852cd905f086C759E8383e09bff1E68B3` | `0xB93e47A4901ADcCcEae4CF7ac4cc74613aBB4cf3` | `0x9224590f55f4bF2f1Cb5CB735967A59E9490D55d` |
| USDS | Ethereum | `0xdC035D45d973E3EC169d2276DDab16f1e407384F` | `0xC05Bf3348f2cf1b6Ec127C601D0978eC59cD6F8e` | `0x817c9329e7E96a624896c423446a79c22F87EA62` |
| LINK | Ethereum | `0x514910771AF9Ca656af840dff83E8264EcF986CA` | `0x093A44369a75aFBC245680EB5B296bab9983557b` | `0xC1908892664e5578e68FBd8e5F07B508883d2F9E` |
| UNI | Ethereum | `0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984` | `0xF01CFBc960A910D58dc01E5D0a57c97eCf2E5302` | `0x662c9E55a54D0f14d29F9Cd5FA95A148712A2010` |
| SKY | Ethereum | `0x56072C95FAA701256059aa122697B133aDEd9279` | `0x6e1cB391C5d3Ce8aCfa8b54E89a43166a33d39C1` | `0x9b9a917Dc4f9dB960c4F9e186Ca57e6f10797303` |
| AVAX | Avalanche | Native AVAX | `0xC2e75F4dB642Cf1b8b5ca9A1DC0450DaE9505352` | `0xa8786243d2ae9116a93bBd045cf04Ab83b563268` |
| HYPE | HyperEVM | Native HYPE | `0xC2e75F4dB642Cf1b8b5ca9A1DC0450DaE9505352` | `0xdfBfd699Fd81943dFA9b3f805a576d93b4cBB09d` |
| USD1 | BSC | `0x8d0D000Ee44948FC98c9B98A4FA4921476f08B0d` | `0x06b4f3A96C529ea0ee6C512778770cEfD00c03b9` | `0x1952860adE184eFB0DeadfaD694771aeD0130736` |
| USDe | BSC | `0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34` | `0x809C4F0C6E62b772f13AAdDBE7A325a4751fA585` | `0x9224590f55f4bF2f1Cb5CB735967A59E9490D55d` |

All 24 directions passed direct on-chain read-back. Ethereum uses 15 confirmations, BSC 20, Avalanche 15, HyperEVM 5 and Anubis 5; each direction uses LayerZero Labs and Horizen as two required DVNs, no optional DVNs, the official local Executor, a 10,000-byte maximum message size and 120,000 enforced `lzReceive` gas. No reserves have been deposited and no production transfer has been performed for these routes.

## OFT and Adapter contracts

| Asset | Anubis OFT | Ethereum Adapter | BSC Adapter | Polygon Adapter | Anubis decimals | sharedDecimals |
| --- | --- | --- | --- | --- | ---: | ---: |
| USDT | `0xC2e75F4dB642Cf1b8b5ca9A1DC0450DaE9505352` | `0xC2e75F4dB642Cf1b8b5ca9A1DC0450DaE9505352` | `0xC2e75F4dB642Cf1b8b5ca9A1DC0450DaE9505352` | `0xC2e75F4dB642Cf1b8b5ca9A1DC0450DaE9505352` | 6 | 6 |
| USDC | `0xcDDF41841f6e0D2611f8f4326f872C0490Cb50d1` | `0xcDDF41841f6e0D2611f8f4326f872C0490Cb50d1` | `0xcDDF41841f6e0D2611f8f4326f872C0490Cb50d1` | `0xcDDF41841f6e0D2611f8f4326f872C0490Cb50d1` | 6 | 6 |
| DAI | `0x2E20D21CD928d662aE52eF86690043f93F14faF0` | `0x2E20D21CD928d662aE52eF86690043f93F14faF0` | `0x2E20D21CD928d662aE52eF86690043f93F14faF0` | `0x2E20D21CD928d662aE52eF86690043f93F14faF0` | 18 | 6 |

The matching addresses across chains result from deterministic deployment by the same account and nonce sequence; each is a separate deployment on its own chain.

Anubis token metadata:

| Contract | Name | Symbol |
| --- | --- | --- |
| `AnubisUSDT` | Anubis LayerZero USDT | USDT |
| `AnubisUSDC` | Anubis LayerZero USDC | USDC |
| `AnubisDAI` | Anubis LayerZero DAI | DAI |

### Native asset pathways

Native assets use LayerZero `NativeOFTAdapter` contracts on their origin chains. Each Adapter directly locks and releases the native currency, while its paired Anubis OFT uses mint/burn accounting. Users do not need wrapped assets on the origin chain.

| Asset | Origin | Native Adapter | Anubis OFT | Origin / Anubis decimals | sharedDecimals |
| --- | --- | --- | --- | ---: | ---: |
| ETH | Ethereum | `0x99c880f03055351A17bDa275E7C165fdeFF89fA5` | `0x6d5BaeC64957733623727054E0638890C7Dcb95D` | 18 / 18 | 6 |
| BNB | BSC | `0x2f29cb66c467983fe6f8b45f05402cf13ee25288` | `0x90acB8Bc1fcd41769E5F0F561eCd5cFEDCd5d069` | 18 / 18 | 6 |
| POL | Polygon | `0x99c880f03055351A17bDa275E7C165fdeFF89fA5` | `0x3BB1a16E8De6cAC26Db61A9710E31C825F82f4F6` | 18 / 18 | 6 |
| TRX | Tron | `TGP8mSn5PbptV9LHZn3tp6bqbLpyVRfCTP` | `0x39Ba7aEDd4b59a7e281CA4FE71F5852CD13a518A` | 6 / 18 | 6 |

The Anubis token names are `Anubis LayerZero ETH`, `Anubis LayerZero BNB`, `Anubis LayerZero POL` and `Anubis LayerZero TRX`; symbols remain `ETH`, `BNB`, `POL` and `TRX`. Each origin Adapter and corresponding Anubis OFT are reciprocal one-to-one peers.

### WBTC pathway

Canonical Ethereum WBTC (`0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599`) is held by a standard self-hosted lock/release `OFTAdapter`; its paired Anubis OFT uses mint/burn accounting.

| Ethereum OFTAdapter | Anubis OFT | Ethereum / Anubis decimals | sharedDecimals |
| --- | --- | ---: | ---: |
| `0xB7028cD6FA27987379dedF161877C618Ec6c9DC4` | `0x329b5a7a5600dBC5F29493894687E2e718A05faD` | 8 / 18 | 6 |

The Anubis token is `Anubis LayerZero WBTC` (`WBTC`). Both contracts are reciprocal one-to-one peers.

### Solana and Tron Adapters

| Network / asset | Canonical underlying | Adapter / OFT Store | Escrow | Program |
| --- | --- | --- | --- | --- |
| Solana USDT | `Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB` | `B5y4NPrL9Q6QFpReBoDhwTTqF2xgKXaEp9iPGXVHDbK4` | `DkYWtpLUSzYZvHChfAxdCCfw7Wy5iCgFGdAo54diEV6T` | `EBtR3iq42WRcqy6kGkMUTYo33etutkjMjS1VTrA8ZL4m` |
| Solana USDC | `EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v` | `EM2nwaze5GpQdbC5sKWFhp4GYs2aTWvjhrTe3ErF3bZu` | `DAqt2VFLoVFKZfpHxL8vA3Y6zZiJeZojeej17mnSJ2zC` | `EBtR3iq42WRcqy6kGkMUTYo33etutkjMjS1VTrA8ZL4m` |
| Tron USDT | `TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t` | `TLJwdwPhwwiYbRnT7C5SSEH9BZ8ZwZ2o8o` | Adapter contract | Solidity OFTAdapter |

The Solana ProgramData account is `FxBFEZH5AEseABA3s38RkEdwTS9sSWUzSR67sojmqLEQ`; its upgrade authority is `DLSzWBi1UbKctB8oDgxtVuF2KDc2eEF1NFBShj2NqzuG`. The Tron Adapter owner/delegate is `TV9PU6qADkXGNFr7C4LN2eFyh8NAjLV6fg`.

## Adapter underlying assets

| Network | USDT | USDC | DAI |
| --- | --- | --- | --- |
| Ethereum | `0xdAC17F958D2ee523a2206206994597C13D831ec7` | `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` | `0x6B175474E89094C44Da98b954EedeAC495271d0F` |
| BSC | `0x55d398326f99059fF775485246999027B3197955` | `0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d` | `0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3` |
| Polygon | `0xc2132D05D31c914a87C6611C10748AEb04B58e8F` (USDT0) | `0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359` (native USDC) | `0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063` |

Polygon USDT uses a self-hosted Adapter around USDT0 as its underlying reserve token. This pathway is not represented as part of the canonical USDT0 OFT mesh.

## Ondo Stocks deployment (Ethereum/BSC ↔ Anubis)

Each pathway uses the corresponding existing Ondo Stocks ERC-20 on Ethereum or BSC as the underlying asset of a self-hosted lock/release `OFTAdapter`. Both source-chain Adapters peer with the same Anubis mint/burn OFT. All assets use 18 local decimals and 6 shared decimals.

| Asset | BSC underlying token | BSC OFTAdapter | Anubis OFT |
| --- | --- | --- | --- |
| AAPLon | `0x390a684ef9cade28a7ad0dfa61ab1eb3842618c4` | `0x0bc7655704c84761e70D06D6aA0dd426Aa846d69` | `0xb0ae37390ae9D3AA534845FC4c8c35f00B285325` |
| AMDon | `0x9f16e46c73b43bdb70861247d537bee4ea18f639` | `0x557048ff7C8A231A2D5C3cCf5f6BC137BcF25F94` | `0xeCA7D0e5BCF5123f20BE68979edaC6ed70cb159c` |
| CRCLon | `0x992879cd8ce0c312d98648875b5a8d6d042cbf34` | `0x0D9530693947e05C8Fc0301F8831423d9cc8E2F6` | `0x4DdA0286196C3333dE68e177FBEE2f0BA0eDa61d` |
| GMEon | `0xdabb9aff4cf02f26d2014e4ca9f94ac6fe6572a3` | `0xD8560867f4D08411D77E9949fA9f8cd5a7a86475` | `0x58DD6b56aA34069fC14CF0c2C76F277f41498E10` |
| GOOGLon | `0x091fc7778e6932d4009b087b191d1ee3bac5729a` | `0x6F4B7518706B5D7Ca0bc4f1fa174C3335348fFB0` | `0x5708f27E8A950976ac942ffE63a0023AE572bb84` |
| INTCon | `0xa528caaa2f96090e379d43f90834c75df54d6e74` | `0x046a4882Fe3CDe0DE3159A27D067Ad79BFd920F0` | `0xEEb477Bed342b64438Ce591fb300dBE058d34d7b` |
| MRNAon | `0x01486675da0764ee780ea7cb65c33062e9b2d28c` | `0xB7028cD6FA27987379dedF161877C618Ec6c9DC4` | `0x23a7660218FaF366b1413BABc454D38DB0449AED` |
| MSFTon | `0x6bfe75d1ad432050ea973c3a3dcd88f02e2444c3` | `0x7C6d24Aa69EF0cE20E84C69639457C9248cc433A` | `0x1fAC642f9C6b5D9762313d3137A4a051042570b2` |
| MSTRon | `0x7313ea16493b2f55054df0131a3a14b043ec8992` | `0x34Ae599FE16c1ac44fCaFa865342953436B62643` | `0xbE721D21Ff4b58eC2E3C148571e32A568EceFaD5` |
| MUon | `0x8b6acf6041a81567f012ff6a4c6d96d5818d74bf` | `0xe56c77Dc136Ed86Cd2A21E78d8917b7A5DAFdaE3` | `0x677EF36142AE9b0e50dcF6690B55FEc47c4b6558` |
| NFLXon | `0x7048f5227b032326cc8dbc53cf3fddd947a2c757` | `0xc7E43B67Ed2AB6467C184084FdE9cc01d24E483A` | `0xb30867c7779C4129fb580437C73858783e34D406` |
| NVDAon | `0xa9ee28c80f960b889dfbd1902055218cba016f75` | `0xd754Ce2602810959ea578978D383F25d7934d455` | `0x5a91750a23d0b299edDC59f715732e695a36bD57` |
| SNDKon | `0x4fd67cb8cfedc718bac984b5936abe3330d0a2a4` | `0x8b67Db61bd0658F21D47d335fafBd8f4fD0F0182` | `0xF7ebF59214FF68cF5d3c2289068A12f0E05A58d6` |
| SPCXon | `0xd0a58bc9d88d3ff48c0294cb7e45937d0e41a928` | `0x7298E75dbAF188BaA2e528188cf253C97D85B60b` | `0x998B24bf62Fd48FB8a18BDc5fDd0390368EC2643` |
| TSLAon | `0x2494b603319d4d9f9715c9f4496d9e0364b59d93` | `0xE44ba3562BE254045591748481789496d8B12815` | `0xBcd0Ed47C04af63EDB38CB677e165d1d7E25395c` |

| Asset | Ethereum underlying token | Ethereum OFTAdapter |
| --- | --- | --- |
| AAPLon | `0x14c3abf95cb9c93a8b82c1cdcb76d72cb87b2d4c` | `0xbf09E3FA640dfc83C81543BC2dA7A7Ec2FA30767` |
| AMDon | `0x0c1f3412a44ff99e40bf14e06e5ea321ae7b3938` | `0x52386039CBC6C80B0c8B70ea9901393824e44E5e` |
| CRCLon | `0x3632dea96a953c11dac2f00b4a05a32cd1063fae` | `0x632B01694fFadbC04b025845Ad555b1F10D64340` |
| GMEon | `0x71d24baeb0a033ec5f90ff65c4210545af378d97` | `0x871BC70C0d14015754909d71e51331454C56120d` |
| GOOGLon | `0xba47214edd2bb43099611b208f75e4b42fdcfedc` | `0x301eC97e7620339A5cC955DA8f2271F613F5ba50` |
| INTCon | `0xfda09936dbd717368de0835ba441d9e62069d36f` | `0xbFABbe98303B78159C15dE8CdA6c04f2213e72D1` |
| MRNAon | `0xa2c1c0b4683a871187d4565eb63abf9aef5947ee` | `0xEB8C79CA79913974cB44686133ea3e451AA17ae2` |
| MSFTon | `0xb812837b81a3a6b81d7cd74cfb19a7f2784555e5` | `0x78E535dD90C11a30dBadFBCb9621648236756Ca4` |
| MSTRon | `0xcabd955322dfbf94c084929ac5e9eca3feb5556f` | `0x76B2813Ba6Bb0e1cF33908ef7C7876a2F7B457B0` |
| MUon | `0x050362ab1072cb2ce74d74770e22a3203ad04ee5` | `0x57F2Bc7947AF0146c768c0C150FAA6E04776f93E` |
| NFLXon | `0x032dec3372f25c41ea8054b4987a7c4832cdb338` | `0x05fDe3a3CC3b77AEb39504DB812A8aa83b4C3f4d` |
| NVDAon | `0x2d1f7226bd1f780af6b9a49dcc0ae00e8df4bdee` | `0x25df0345D524c982d68f99187AB79CFC9FDEF225` |
| SNDKon | `0x71e2400cf1cb83204f33794ed326636a71a9aafc` | `0x00E31E70F1d2Ee4bB06c237bcd366417106DcCfb` |
| SPCXon | `0xc9eef266834730340a55b6cc24621b31baf55581` | `0x88B931ad2F1d9809f786E396c467b031876ef9BB` |
| TSLAon | `0xf6b1117ec07684d3958cad8beb1b302bfd21103f` | `0x262d46113849EF2948845a9f10ee109164469c98` |

Anubis names use `Anubis LayerZero <symbol>` and preserve the corresponding source symbol.

### Ondo Stocks pathway configuration and validation

All 60 pathway directions across 45 contracts have been read back from chain and verified for contract bytecode, Owner, Endpoint, reciprocal peer, explicit ULN302 Send/Receive Libraries, Executor, confirmations, two required DVNs and enforced options:

- BSC → Anubis confirmations: 20
- Ethereum → Anubis confirmations: 15
- Anubis → BSC confirmations: 5
- Required DVNs on BSC: LayerZero Labs and Horizen
- Required DVNs on Anubis: LayerZero Labs and Horizen
- Required DVN count: 2; optional DVN count: 0
- Enforced `lzReceive` gas: 120,000 on both sides
- Maximum message size: 10,000 bytes

Representative Config Checker links:

- [AAPLon: BSC → Anubis](https://feat-node-visualization.configchecker.pages.dev/?sourceNetwork=bsc&sourceAddress=0x0bc7655704c84761e70D06D6aA0dd426Aa846d69&remoteNetworks=anubis)
- [AAPLon: Ethereum → Anubis](https://feat-node-visualization.configchecker.pages.dev/?sourceNetwork=ethereum&sourceAddress=0xbf09E3FA640dfc83C81543BC2dA7A7Ec2FA30767&remoteNetworks=anubis)
- [AAPLon: Anubis → BSC](https://feat-node-visualization.configchecker.pages.dev/?sourceNetwork=anubis&sourceAddress=0xb0ae37390ae9D3AA534845FC4c8c35f00B285325&remoteNetworks=bsc)
- The complete 15-asset address register is included in the table above; the representative links demonstrate the same reciprocal configuration applied to all 15 pathways.

The Config Checker currently requires the Anubis custom RPC `https://rpc2.anubispace.org`. Its default Anubis RPC may return incomplete reads and incorrectly report the Anubis OFT as an EOA or show `No peer set`. With the custom RPC selected, the reciprocal peer, DVN, confirmation and enforced-option checks pass.

No Ondo Stocks were deposited into the Adapters and no production cross-chain stock transfer has been performed. Adapter reserves and Anubis OFT supplies therefore remain zero.

All 15 Ethereum Adapters publish source on Etherscan, all 15 BSC Adapters publish source on BscScan, and all 15 Anubis OFTs publish source on AnubisScan. Representative links: [AAPLon Ethereum Adapter](https://etherscan.io/address/0xbf09E3FA640dfc83C81543BC2dA7A7Ec2FA30767#code), [AAPLon BSC Adapter](https://bscscan.com/address/0x0bc7655704c84761e70D06D6aA0dd426Aa846d69#code) and [AAPLon Anubis OFT](https://anubisscan.io/address/0xb0ae37390ae9D3AA534845FC4c8c35f00B285325?tab=contract).

## Peer topology

For each asset in the Ethereum/BSC/Polygon EVM mesh:

- The Anubis OFT has peers for Ethereum EID `30101`, BSC EID `30102` and Polygon EID `30109`.
- Each source-chain Adapter has one peer for Anubis EID `30465`.
- Each EVM peer value is the corresponding 20-byte contract address left-zero-padded to `bytes32`.
- All 18 directional peer values have been read back from chain and verified.

| Asset | Peer value (`bytes32`) |
| --- | --- |
| USDT | `0x000000000000000000000000c2e75f4db642cf1b8b5ca9a1dc0450dae9505352` |
| USDC | `0x000000000000000000000000cddf41841f6e0d2611f8f4326f872c0490cb50d1` |
| DAI | `0x0000000000000000000000002e20d21cd928d662ae52ef86690043f93f14faf0` |

The Solana USDT and USDC Stores are reciprocally peered one-to-one with the corresponding Anubis OFTs under EID `30168`. The Tron USDT Adapter is reciprocally peered with the Anubis USDT OFT under EID `30420`. These extensions do not add a Solana DAI or Tron USDC/DAI pathway.

## Pathway security configuration

All 18 directions use:

- ULN302 send and receive libraries
- Required DVNs: LayerZero Labs and Horizen
- Required DVN count: 2
- Optional DVN count: 0
- Official local-network Executor
- Maximum message size: 10,000 bytes
- Enforced `lzReceive` gas: 120,000

| Direction | Confirmations |
| --- | ---: |
| Ethereum → Anubis | 15 |
| Anubis → Ethereum | 5 |
| BSC → Anubis | 20 |
| Anubis → BSC | 5 |
| Polygon → Anubis | 120 |
| Anubis → Polygon | 5 |

Solana and Tron extensions use the same two required DVNs (LayerZero Labs and Horizen), no optional DVNs, the official local Executor and explicit ULN302 send/receive libraries.

The native-asset pathways use the same security policy. ETH uses 15 Ethereum confirmations, BNB uses 20 BSC confirmations, POL uses 120 Polygon confirmations and TRX uses 20 Tron confirmations; the Anubis side uses 5 confirmations. All eight directions were read back and verified for reciprocal Peer, Send/Receive Library, Executor, ULN configuration, two required DVNs and Enforced Options.

WBTC uses the same Ethereum ↔ Anubis policy: 15/5 confirmations, LayerZero Labs and Horizen as the two required DVNs, no optional DVNs, official Executors, 10,000-byte maximum messages and 120,000 enforced `lzReceive` gas. Both directions were read back with no differences.

| Direction | Confirmations | Enforced receive option |
| --- | ---: | --- |
| Solana → Anubis | 32 | 120,000 EVM gas |
| Anubis → Solana | 5 | 200,000 Solana CU + 2,039,280 lamports ATA rent |
| Tron → Anubis | 20 | 120,000 EVM gas |
| Anubis → Tron | 5 | 120,000 TVM gas |

Both Solana pathways pass the official LayerZero `lz:oapp:wire --assert` check with zero configuration differences. The Tron pathway passes all eight direct read-back checks: reciprocal peers, send/receive libraries, ULN/Executor configurations and enforced options on both chains.

Config Checker:

- [USDT: Anubis → Ethereum/BSC/Polygon](https://configchecker.pages.dev/?sourceNetwork=anubis&sourceAddress=0xC2e75F4dB642Cf1b8b5ca9A1DC0450DaE9505352&remoteNetworks=ethereum,bsc,polygon)
- [USDC: Anubis → Ethereum/BSC/Polygon](https://configchecker.pages.dev/?sourceNetwork=anubis&sourceAddress=0xcDDF41841f6e0D2611f8f4326f872C0490Cb50d1&remoteNetworks=ethereum,bsc,polygon)
- [DAI: Anubis → Ethereum/BSC/Polygon](https://configchecker.pages.dev/?sourceNetwork=anubis&sourceAddress=0x2E20D21CD928d662aE52eF86690043f93F14faF0&remoteNetworks=ethereum,bsc,polygon)
- [ETH: Anubis → Ethereum](https://configchecker.pages.dev/?sourceNetwork=anubis&sourceAddress=0x6d5BaeC64957733623727054E0638890C7Dcb95D&remoteNetworks=ethereum)
- [BNB: Anubis → BSC](https://configchecker.pages.dev/?sourceNetwork=anubis&sourceAddress=0x90acB8Bc1fcd41769E5F0F561eCd5cFEDCd5d069&remoteNetworks=bsc)
- [POL: Anubis → Polygon](https://configchecker.pages.dev/?sourceNetwork=anubis&sourceAddress=0x3BB1a16E8De6cAC26Db61A9710E31C825F82f4F6&remoteNetworks=polygon)
- [TRX: Anubis → Tron](https://configchecker.pages.dev/?sourceNetwork=anubis&sourceAddress=0x39Ba7aEDd4b59a7e281CA4FE71F5852CD13a518A&remoteNetworks=tron)
- [WBTC: Anubis → Ethereum](https://feat-node-visualization.configchecker.pages.dev/?sourceNetwork=anubis&sourceAddress=0x329b5a7a5600dBC5F29493894687E2e718A05faD&remoteNetworks=ethereum)
- [WBTC: Ethereum → Anubis](https://feat-node-visualization.configchecker.pages.dev/?sourceNetwork=ethereum&sourceAddress=0xB7028cD6FA27987379dedF161877C618Ec6c9DC4&remoteNetworks=anubis)

## Ownership

| Role | Address |
| --- | --- |
| Owner | `0x59Dc82A7Ee06d825035D444A9064e8307Fa7977a` |
| Endpoint Delegate | `0x59Dc82A7Ee06d825035D444A9064e8307Fa7977a` |

The EVM contracts are non-upgradeable. Owner/Delegate cannot directly mint Anubis assets or withdraw Adapter reserves. The Solana Program is upgradeable under the authority disclosed above.

## Source verification

Compiler settings: Solidity `v0.8.22+commit.4fc1097e`, optimizer enabled with 200 runs, EVM target `paris`.

### Source and dependency versions

The `contracts/` directory contains the project-owned Solidity source used by the EVM and Tron deployments. Imported LayerZero and OpenZeppelin source remains available through the published package versions below.

| Component | Version / build reference |
| --- | --- |
| Solidity compiler | `v0.8.22+commit.4fc1097e` |
| Solidity optimizer | Enabled, 200 runs |
| EVM target | `paris` |
| Hardhat | `2.29.1` |
| `@layerzerolabs/oft-evm` | `3.2.1` |
| `@layerzerolabs/oapp-evm` | `0.3.3` |
| `@openzeppelin/contracts` | `5.6.1` |
| Solana OFT Program source snapshot | LayerZero commit `c6144b126b81cf879a5740d943fc7e8a2bd57031` |
| Solana `oapp-latest` / `utils-latest` dependencies | LayerZero commit `c09287a8b1f236fcc057f474d8a773a0fb7758df` |
| `@layerzerolabs/oft-v2-solana-sdk` | `3.0.142` resolved (`^3.0.136` declared) |
| `@layerzerolabs/lz-solana-sdk-v2` | `3.0.142` resolved (`^3.0.136` declared) |
| `@layerzerolabs/devtools-solana` | `3.1.0` |
| Anchor | `0.31.1` |
| Solana verifiable-build image | `solanafoundation/solana-verifiable-build:2.1.0` |

Tron reuses the same project-owned `ProductionOFTAdapter.sol` Solidity source and the same Solidity compiler, optimizer and EVM-target settings listed above. The Solana Program is not Solidity-based; its Rust source is published under `solana/programs/oft/`.

| Network | USDT | USDC | DAI |
| --- | --- | --- | --- |
| Anubis | [Explorer](https://browser.anubispace.org/address/0xC2e75F4dB642Cf1b8b5ca9A1DC0450DaE9505352) | [Explorer](https://browser.anubispace.org/address/0xcDDF41841f6e0D2611f8f4326f872C0490Cb50d1) | [Explorer](https://browser.anubispace.org/address/0x2E20D21CD928d662aE52eF86690043f93F14faF0) |
| Ethereum | [Etherscan](https://etherscan.io/address/0xC2e75F4dB642Cf1b8b5ca9A1DC0450DaE9505352#code) | [Etherscan](https://etherscan.io/address/0xcDDF41841f6e0D2611f8f4326f872C0490Cb50d1#code) | [Etherscan](https://etherscan.io/address/0x2E20D21CD928d662aE52eF86690043f93F14faF0#code) |
| BSC | [BscScan](https://bscscan.com/address/0xC2e75F4dB642Cf1b8b5ca9A1DC0450DaE9505352#code) | [BscScan](https://bscscan.com/address/0xcDDF41841f6e0D2611f8f4326f872C0490Cb50d1#code) | [BscScan](https://bscscan.com/address/0x2E20D21CD928d662aE52eF86690043f93F14faF0#code) |
| Polygon | [PolygonScan](https://polygonscan.com/address/0xC2e75F4dB642Cf1b8b5ca9A1DC0450DaE9505352#code) | [PolygonScan](https://polygonscan.com/address/0xcDDF41841f6e0D2611f8f4326f872C0490Cb50d1#code) | [PolygonScan](https://polygonscan.com/address/0x2E20D21CD928d662aE52eF86690043f93F14faF0#code) |

All contracts publish source on their respective explorer. Every source-chain Adapter also has an independent Sourcify exact match for creation and runtime bytecode.

Native asset source verification is complete with the same compiler settings:

| Asset | Origin Adapter source | Anubis OFT source |
| --- | --- | --- |
| ETH | [Etherscan](https://etherscan.io/address/0x99c880f03055351A17bDa275E7C165fdeFF89fA5#code) | [AnubisScan](https://anubisscan.io/address/0x6d5BaeC64957733623727054E0638890C7Dcb95D?tab=contract) |
| BNB | [BscScan](https://bscscan.com/address/0x2f29cb66c467983fe6f8b45f05402cf13ee25288#code) | [AnubisScan](https://anubisscan.io/address/0x90acB8Bc1fcd41769E5F0F561eCd5cFEDCd5d069?tab=contract) |
| POL | [PolygonScan](https://polygonscan.com/address/0x99c880f03055351A17bDa275E7C165fdeFF89fA5#code) | [AnubisScan](https://anubisscan.io/address/0x3BB1a16E8De6cAC26Db61A9710E31C825F82f4F6?tab=contract) |
| TRX | [Tronscan](https://tronscan.org/#/contract/TGP8mSn5PbptV9LHZn3tp6bqbLpyVRfCTP/code) | [AnubisScan](https://anubisscan.io/address/0x39Ba7aEDd4b59a7e281CA4FE71F5852CD13a518A?tab=contract) |

Etherscan, BscScan and PolygonScan returned `Pass - Verified`; all four Anubis OFTs report `is_verified: true`; Tronscan reports `verify_status: 2`. The BSC and Polygon native Adapters additionally have Sourcify creation and runtime bytecode Exact Matches.

WBTC verification is complete: [Ethereum OFTAdapter](https://etherscan.io/address/0xB7028cD6FA27987379dedF161877C618Ec6c9DC4#code) and [Anubis OFT](https://anubisscan.io/address/0x329b5a7a5600dBC5F29493894687E2e718A05faD?tab=contract).

For the new extensions, chain and configuration verification and public source/build verification have passed:

- Solana: Program identity, ProgramData and upgrade authority were verified on chain. OtterSec's remote native build also completed reproducible verification: the on-chain and rebuilt executable SHA-256 hashes both equal `ad616930ed1e515d4e08370cd51066de72ee9be10ff569482be3d984edeb10d0`. The verification uses LayerZero commit `c6144b126b81cf879a5740d943fc7e8a2bd57031` and build image `solanafoundation/solana-verifiable-build:2.1.0`. Verification metadata was published in transaction `4mXL8imHq5cTmL1VWcwDTuRrU24An2UR95ZHYnxq9EMKM3TRn2NuFDQ3hKrqkyQjdv8MJyQGjyRW93k5Di9n9a1D`.
- Tron: deployed runtime bytecode, constructor state, owner, Endpoint, underlying token and pathway configuration were verified on chain. Tronscan accepted and published all 50 source units (`status: 2`) as `ProductionOFTAdapter`, compiled with Solidity `v0.8.22+commit.4fc1097e`, EVM version `paris`, optimizer enabled and 200 runs.

Explorer and verification references: [Solana OFT Program](https://solscan.io/account/EBtR3iq42WRcqy6kGkMUTYo33etutkjMjS1VTrA8ZL4m), [Solana USDT Store](https://solscan.io/account/B5y4NPrL9Q6QFpReBoDhwTTqF2xgKXaEp9iPGXVHDbK4), [Solana USDC Store](https://solscan.io/account/EM2nwaze5GpQdbC5sKWFhp4GYs2aTWvjhrTe3ErF3bZu), [OtterSec verification status](https://verify.osec.io/status/EBtR3iq42WRcqy6kGkMUTYo33etutkjMjS1VTrA8ZL4m), [OtterSec verification job](https://verify.osec.io/job/44575279-c2bf-4345-a3f2-c5daa9cfe848), and [Tron USDT Adapter](https://tronscan.org/#/contract/TLJwdwPhwwiYbRnT7C5SSEH9BZ8ZwZ2o8o/code).

## Production transfer validation

A dedicated non-admin wallet executed a 0.1-token round trip for every asset and source chain. All 9 round trips / 18 directions were delivered successfully. After reconciliation:

- The test wallet recovered exactly 1.0 of each underlying token on each source chain.
- All nine Adapter test reserve balances returned to zero.
- All three Anubis OFT total supplies returned to zero.

| Network | Asset | Source → Anubis | Anubis → source |
| --- | --- | --- | --- |
| Ethereum | USDT | [LZ Scan](https://layerzeroscan.com/tx/0xb8c900c059c853cc819e01838e4a360ee3d127a8c4c55960a9ae0e2f1c606e4a) | [LZ Scan](https://layerzeroscan.com/tx/0xc81ff2810af3f4006f98389d0350268eaae6aa28c1acdb8ae13273b28990be64) |
| Ethereum | USDC | [LZ Scan](https://layerzeroscan.com/tx/0x8382b4e893284a2a56b27b2d91cb060714de2e6cc225ed7fe8e680d829d87162) | [LZ Scan](https://layerzeroscan.com/tx/0xf89640e1ca47280df3bfa52b9ae60f9130d5422074c0dad95f765141d09292fe) |
| Ethereum | DAI | [LZ Scan](https://layerzeroscan.com/tx/0x59f5eee85a795447779d11f2ff91dbaf5866b8625a8e3aefae82772651c39cf5) | [LZ Scan](https://layerzeroscan.com/tx/0xe1901c59ea9258500ebd0fc1e8e3a2020ed0f2320da7729bdee5154d908bd91c) |
| BSC | USDT | [LZ Scan](https://layerzeroscan.com/tx/0x569be6e1f87a687e7607623b77885b03246a275f8f613c17f0097ff85b22b9b9) | [LZ Scan](https://layerzeroscan.com/tx/0xe8cfb14464758fc4cff85e061c20885a391319e7b6c3ced67cf27173d0d28d08) |
| BSC | USDC | [LZ Scan](https://layerzeroscan.com/tx/0x3f2678eb50f5229d7e7ee3e114d26109b6e15f9c90b2a2bf42ae744d819aea5e) | [LZ Scan](https://layerzeroscan.com/tx/0x5807ca5b4007c0066691c9dd6156647a8c5e8bc82f4a879cc5aece259dd0920b) |
| BSC | DAI | [LZ Scan](https://layerzeroscan.com/tx/0x08f7b144ea891581d962ef49bf789bded707c927c8f404abc6584d97dc217b46) | [LZ Scan](https://layerzeroscan.com/tx/0x3dc81e17afffffa555e2437944f3156ed24fdf502e1cfc86b04f1564b8e72f8c) |
| Polygon | USDT | [LZ Scan](https://layerzeroscan.com/tx/0x40977970d3c419699dee8bba341a9a669a18edc8ff41c1a00231ac2a3c00a7a6) | [LZ Scan](https://layerzeroscan.com/tx/0x400401ba57fc5c9fdc631c16c641583ed9f48e8e45641df17486414a404e67a7) |
| Polygon | USDC | [LZ Scan](https://layerzeroscan.com/tx/0xc7f58ac3e242124a073ce9b03e03d70fe9ca124cda112d2ab27bdcaaf7bfa801) | [LZ Scan](https://layerzeroscan.com/tx/0x806984f350b7055f1afef0fe41a32775a021b0d956ed459ec3476165cbc3f514) |
| Polygon | DAI | [LZ Scan](https://layerzeroscan.com/tx/0xfd5bcb822ac66f36cef65a25f27152423d4be81305254ac794ebf2b75eafc2d9) | [LZ Scan](https://layerzeroscan.com/tx/0x35693cb025a5a10a58aa791ff8e6729f0d0f09863ac9728a3254e2dd6c092c7b) |

No reserve deposit or production transfer test has been made for the Solana USDT/USDC, Tron USDT, ETH/BNB/POL/TRX native-asset or WBTC pathways.
