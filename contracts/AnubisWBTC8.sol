// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { AnubisOFT } from "./AnubisOFT.sol";

/// @notice Anubis representation compatible with the official LayerZero WBTC V2 Mesh.
contract AnubisWBTC8 is AnubisOFT {
    constructor(address endpoint_, address delegate_)
        AnubisOFT("Anubis LayerZero WBTC", "WBTC", endpoint_, delegate_)
    {}

    function sharedDecimals() public pure override returns (uint8) {
        return 8;
    }

    /// @notice Match canonical Ethereum WBTC's local token precision.
    function decimals() public pure override returns (uint8) {
        return 8;
    }
}
