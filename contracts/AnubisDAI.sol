// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { AnubisOFT } from "./AnubisOFT.sol";

/// @notice Anubis DAI candidate; peers remain disabled until its canonical mesh is confirmed.
contract AnubisDAI is AnubisOFT {
    constructor(address endpoint, address delegate_)
        AnubisOFT("Anubis LayerZero DAI", "DAI", endpoint, delegate_)
    {}
}
