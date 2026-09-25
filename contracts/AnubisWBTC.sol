// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { AnubisOFT } from "./AnubisOFT.sol";

/// @notice Anubis representation of canonical Ethereum WBTC held by an OFTAdapter.
contract AnubisWBTC is AnubisOFT {
    constructor(address endpoint_, address delegate_)
        AnubisOFT("Anubis LayerZero WBTC", "WBTC", endpoint_, delegate_)
    {}
}
