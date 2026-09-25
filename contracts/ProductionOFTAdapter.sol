// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { OFTAdapter } from "@layerzerolabs/oft-evm/contracts/OFTAdapter.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Self-hosted production adapter for an existing ERC20 asset.
contract ProductionOFTAdapter is OFTAdapter {
    constructor(address token_, address endpoint_, address delegate_)
        OFTAdapter(token_, endpoint_, delegate_)
        Ownable(delegate_)
    {}
}
