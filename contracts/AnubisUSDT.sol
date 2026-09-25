// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { AnubisOFT } from "./AnubisOFT.sol";

/// @notice Anubis omnichain USDT for the self-hosted LayerZero mesh.
contract AnubisUSDT is AnubisOFT {
    constructor(address endpoint, address delegate_)
        AnubisOFT("Anubis LayerZero USDT", "USDT", endpoint, delegate_)
    {}

    function decimals() public pure override returns (uint8) { return 6; }
}
