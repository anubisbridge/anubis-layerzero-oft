// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { AnubisOFT } from "./AnubisOFT.sol";

/// @notice Anubis representation of a native asset locked by a remote NativeOFTAdapter.
contract AnubisNativeAssetOFT is AnubisOFT {
    constructor(string memory name_, string memory symbol_, address endpoint_, address delegate_)
        AnubisOFT(name_, symbol_, endpoint_, delegate_)
    {}
}
