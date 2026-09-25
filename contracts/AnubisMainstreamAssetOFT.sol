// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { AnubisOFT } from "./AnubisOFT.sol";

/// @notice Anubis mint/burn representation paired with a self-hosted source-chain Adapter.
contract AnubisMainstreamAssetOFT is AnubisOFT {
    constructor(string memory name_, string memory symbol_, address endpoint_, address delegate_)
        AnubisOFT(name_, symbol_, endpoint_, delegate_)
    {}
}
