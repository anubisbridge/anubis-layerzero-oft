// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { AnubisOFT } from "./AnubisOFT.sol";

/// @notice Anubis USDC candidate; peers remain disabled until its canonical mesh is confirmed.
contract AnubisUSDC is AnubisOFT {
    constructor(address endpoint, address delegate_)
        AnubisOFT("Anubis LayerZero USDC", "USDC", endpoint, delegate_)
    {}

    function decimals() public pure override returns (uint8) { return 6; }
}
