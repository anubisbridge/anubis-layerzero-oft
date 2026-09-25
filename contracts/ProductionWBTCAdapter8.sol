// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { OFTAdapter } from "@layerzerolabs/oft-evm/contracts/OFTAdapter.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Ethereum WBTC Adapter compatible with the official LayerZero WBTC V2 Mesh.
contract ProductionWBTCAdapter8 is OFTAdapter {
    constructor(address token_, address endpoint_, address delegate_)
        OFTAdapter(token_, endpoint_, delegate_)
        Ownable(delegate_)
    {}

    function sharedDecimals() public pure override returns (uint8) {
        return 8;
    }
}
