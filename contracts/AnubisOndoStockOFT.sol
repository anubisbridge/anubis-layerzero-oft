// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { AnubisOFT } from "./AnubisOFT.sol";

/// @notice Anubis-side mint/burn OFT paired with a BSC Ondo Stocks adapter.
/// @dev This contract does not claim issuance or endorsement by Ondo.
contract AnubisOndoStockOFT is AnubisOFT {
    constructor(string memory name_, string memory symbol_, address endpoint_, address delegate_)
        AnubisOFT(name_, symbol_, endpoint_, delegate_)
    {}
}

