// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { NativeOFTAdapter } from "@layerzerolabs/oft-evm/contracts/NativeOFTAdapter.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Self-hosted production adapter for a chain's native currency.
/// @dev The native amount and LayerZero native fee are both supplied through
/// msg.value. Only one default NativeOFTAdapter should exist in an asset mesh.
contract ProductionNativeOFTAdapter is NativeOFTAdapter {
    constructor(uint8 localDecimals_, address endpoint_, address delegate_)
        NativeOFTAdapter(localDecimals_, endpoint_, delegate_)
        Ownable(delegate_)
    {}
}
