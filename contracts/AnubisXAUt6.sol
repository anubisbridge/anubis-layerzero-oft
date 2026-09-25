// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { AnubisOFT } from "./AnubisOFT.sol";

/// @notice Anubis representation matching canonical Ethereum XAUt precision.
contract AnubisXAUt6 is AnubisOFT {
    constructor(address endpoint_, address delegate_)
        AnubisOFT("Anubis LayerZero XAUt", "XAUt", endpoint_, delegate_)
    {}

    /// @notice Match canonical Ethereum XAUt's six-decimal local precision.
    function decimals() public pure override returns (uint8) {
        return 6;
    }
}
